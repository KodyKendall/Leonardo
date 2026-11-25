# frozen_string_literal: true
#
# bin/lib/rails8_scan.rb — LP-52: find overlay code that Rails 8.1 / Ruby 3.4 removed, and fix
# the mechanical cases.
#
#   ruby rails8_scan.rb scan  <overlay rails/ dir> [--gemfile-lock PATH]   # read-only, prints JSON
#   ruby rails8_scan.rb apply <overlay rails/ dir> [--gemfile-lock PATH]   # rewrites auto-fixes
#
# JSON: {"auto": [finding], "human": [finding]}, finding = {file, line, pattern, detail}.
# `file` is relative to the overlay dir. Stdlib only: it runs inside the 0.8.0 image (or any
# Ruby), never needs the app booted. Used by bin/rails8-scan and bin/upgrade-to-0.8.
#
# Auto-fix (one revertable "Rails 8 codemods" commit, see bin/upgrade-to-0.8):
#   enum_keyword_form   enum status: {...}           -> enum :status, {...}  (_prefix: -> prefix: ...)
#   proxy_object        ActiveSupport::ProxyObject   -> BasicObject
#   removed_config      config.<key removed in 8.x> = ...  -> line deleted
# Needs a human:
#   enum_multiple_in_one_call   enum a: {...}, b: {...}  (Rails 8 takes one enum per call)
#   application_secrets         Rails.application.secrets (removed; move to credentials/ENV)
#   devise_controller_override  < Devise::*Controller   (Devise 4 -> 5 in the 0.8.0 image)
#   bundled_gem_require         require "observer" etc. — a Ruby 3.4 bundled gem not in the image
require "json"
require "set"

module Rails8Scan
  SCAN_DIRS = %w[app config db lib].freeze
  EXTENSIONS = %w[.rb .rake .erb .jbuilder .builder].freeze

  # Gone from Rails 8.1. Checked against the 0.8.0 image (2026-11-18): the active_record.* keys
  # raise NoMethodError at boot; the rest are no longer read anywhere in Rails 8.1, so deleting
  # the line changes nothing. Deleting a key that still exists WOULD change behaviour (e.g.
  # active_support.to_time_preserves_timezone is only deprecated), so never add keys from memory.
  REMOVED_CONFIG = %w[
    read_encrypted_secrets
    active_record.commit_transaction_on_non_local_return
    active_record.allow_deprecated_singular_associations_name
    active_record.warn_on_records_fetched_greater_than
    active_record.sqlite3_deprecated_warning
    active_record.legacy_connection_handling
    active_support.use_rfc4122_namespaced_uuids
    active_support.disable_to_s_conversion
    active_support.remove_deprecated_time_with_zone_name
    active_job.use_big_decimal_serializer
  ].freeze

  # Ruby 3.4 moved these from default to bundled gems: a bare require fails unless the gem is in
  # the bundle. Flagged only when the image's Gemfile.lock does not have it.
  BUNDLED_34 = %w[
    abbrev base64 bigdecimal csv drb getoptlong mutex_m nkf observer racc resolv-replace rinda syslog
  ].freeze

  ENUM_OPTIONS = %w[prefix suffix scopes default instance_methods validate].freeze

  # Every version of the Devise overrides Leonardo itself has ever shipped (sha256 of the whole
  # file, from `git log --all` on 2026-11-18). These are on every box and are covered by the
  # overlay specs that pass on Devise 5 (incl. sign_in_csrf_race_spec), so a byte-identical copy
  # is platform code, not a customer change. Any edit at all changes the hash -> needs a human.
  STOCK_DEVISE_OVERRIDES = {
    "app/controllers/users/registrations_controller.rb" => %w[
      97612cc8aedd2211bce5bbc17da3e25b9e94c8be5c466d5c7a450ad870152d82
      f1521693b3a60e8f00cf4d6a26d46c415006b3b6e8fab3f2d21232937688999f
    ],
    "app/controllers/users/sessions_controller.rb" => %w[
      f6aea40cc59d7cab2583bbba0367c490c8029f341ef2729aa35a720f859a66ac
    ]
  }.freeze

  def stock_devise_override?(rel_path, text)
    require "digest"
    STOCK_DEVISE_OVERRIDES.fetch(rel_path, []).include?(Digest::SHA256.hexdigest(text))
  end
  module_function :stock_devise_override?

  Finding = Struct.new(:file, :line, :pattern, :detail) do
    def to_h = { "file" => file, "line" => line, "pattern" => pattern, "detail" => detail }
  end

  module_function

  def files(root)
    SCAN_DIRS.flat_map { |d| Dir.glob(File.join(root, d, "**", "*")) }
             .select { |f| File.file?(f) && EXTENSIONS.include?(File.extname(f)) }
             .reject { |f| f.include?("/node_modules/") }
             .sort
  end

  def locked_gems(lock_path)
    return nil unless lock_path && File.file?(lock_path)
    File.read(lock_path).scan(/^    ([a-z0-9_.-]+) \(/).flatten.to_set
  end

  # Walk a Ruby statement starting at lines[i] until its brackets balance and the line does
  # not end in a continuation. Returns the index of the last line. Strings are skipped so a
  # brace inside quotes does not count.
  def statement_end(lines, i)
    depth = 0
    j = i
    loop do
      depth += bracket_delta(lines[j])
      text = lines[j].sub(/#.*$/, "").rstrip
      break if depth <= 0 && !text.end_with?(",", "\\") || j == lines.size - 1
      j += 1
    end
    j
  end

  def bracket_delta(line)
    delta = 0
    quote = nil
    line.each_char do |c|
      if quote
        quote = nil if c == quote
      elsif c == '"' || c == "'"
        quote = c
      elsif c == "#"
        break
      elsif "{[(".include?(c)
        delta += 1
      elsif "}])".include?(c)
        delta -= 1
      end
    end
    delta
  end

  # Top-level `name: {` / `name: [` / `name: %i[` keys of an enum call — one per enum defined.
  def enum_names(statement)
    body = statement.sub(/\A\s*enum\s+/, "")
    names = []
    depth = 0
    quote = nil
    i = 0
    while i < body.size
      c = body[i]
      if quote
        quote = nil if c == quote
      elsif c == '"' || c == "'"
        quote = c
      elsif "{[(".include?(c)
        depth += 1
      elsif "}])".include?(c)
        depth -= 1
      elsif depth.zero? && (m = body[i..].match(/\A([a-z_]\w*):\s*(\{|\[|%[iIwW][\[(])/)) &&
            (i.zero? || body[i - 1] !~ /\w/)
        names << m[1] unless m[1].start_with?("_") || ENUM_OPTIONS.include?(m[1])
      end
      i += 1
    end
    names
  end

  def rel(root, path) = path.delete_prefix(root.chomp("/") + "/")

  # Returns [findings, new_contents_or_nil] for one file.
  def check_file(root, path, locked)
    text = File.read(path, encoding: "UTF-8")
    lines = text.lines
    found = []
    out = lines.dup
    rf = rel(root, path)
    i = 0
    while i < lines.size
      line = lines[i]
      code = line.sub(/#.*$/, "")

      if code =~ /^\s*enum\s+[a-z_]\w*:\s/
        last = statement_end(lines, i)
        stmt = lines[i..last].join
        names = enum_names(stmt)
        if names.size > 1
          found << Finding.new(rf, i + 1, "enum_multiple_in_one_call", "enums #{names.join(', ')} in one call")
        else
          found << Finding.new(rf, i + 1, "enum_keyword_form", "enum #{names.first}: -> enum :#{names.first},")
          out[i] = out[i].sub(/^(\s*)enum\s+([a-z_]\w*):\s*/, '\1enum :\2, ')
          (i..last).each do |k|
            out[k] = out[k].gsub(/(?<![\w])_(#{ENUM_OPTIONS.join('|')}):/, '\1:')
          end
        end
        i = last + 1
        next
      end

      if code.include?("ActiveSupport::ProxyObject")
        found << Finding.new(rf, i + 1, "proxy_object", "ActiveSupport::ProxyObject -> BasicObject")
        out[i] = out[i].gsub("ActiveSupport::ProxyObject", "BasicObject")
      end

      if (m = code.match(/^\s*config\.(#{REMOVED_CONFIG.map { Regexp.escape(_1) }.join('|')})\s*=/))
        if statement_end(lines, i) == i
          found << Finding.new(rf, i + 1, "removed_config", "config.#{m[1]} (removed in Rails 8)")
          out[i] = nil
        else
          found << Finding.new(rf, i + 1, "removed_config_multiline", "config.#{m[1]} spans lines")
        end
      end

      if code.include?("Rails.application.secrets")
        found << Finding.new(rf, i + 1, "application_secrets", "Rails.application.secrets was removed in Rails 8")
      end

      if code =~ /<\s*(::)?Devise::\w+Controller\b/ && !stock_devise_override?(rf, text)
        found << Finding.new(rf, i + 1, "devise_controller_override", "Devise 4 -> 5: check overridden actions")
      end

      if (m = code.match(/^\s*require\s*\(?\s*["']([\w-]+)["']/)) && BUNDLED_34.include?(m[1]) &&
         locked && !locked.include?(m[1])
        found << Finding.new(rf, i + 1, "bundled_gem_require", "require \"#{m[1]}\": Ruby 3.4 bundled gem, not in the image")
      end

      i += 1
    end
    new_text = out.compact.join
    [found, new_text == text ? nil : new_text]
  end

  AUTO = %w[enum_keyword_form proxy_object removed_config].freeze

  def run(mode, root, lock)
    locked = locked_gems(lock)
    result = { "auto" => [], "human" => [] }
    files(root).each do |path|
      found, new_text = check_file(root, path, locked)
      found.each { |f| result[AUTO.include?(f.pattern) ? "auto" : "human"] << f.to_h }
      # Write in place (same inode) so the file keeps its owner and mode on the box.
      File.open(path, "r+") { |io| io.truncate(0); io.write(new_text) } if mode == "apply" && new_text
    end
    result
  end
end

module Rails8Scan
  BUCKETS = %w[0_fixes auto_only needs_human].freeze

  # One box's result: the scan JSON + the zeitwerk:check exit code and output (run by the
  # caller against the overlay inside the 0.8.0 image) -> bucket + everything the CSV needs.
  def report(scan, zeitwerk_rc, zeitwerk_log, box: nil, image_tags: nil)
    zeitwerk_ok = zeitwerk_rc.to_i.zero?
    zw_detail = zeitwerk_ok ? "ok" : "failed: #{zeitwerk_log.lines.map(&:strip).grep(/Error|expected|uninitialized|aborted/i).first || zeitwerk_log.lines.last.to_s.strip}"
    bucket = if scan["human"].any? || !zeitwerk_ok then "needs_human"
             elsif scan["auto"].any? then "auto_only"
             else "0_fixes" end
    { "box" => box, "image_tags" => image_tags, "bucket" => bucket,
      "auto" => scan["auto"], "human" => scan["human"], "zeitwerk" => zw_detail[0, 300] }
  end
  module_function :report

  CSV_HEADER = %w[box node owner_tier image_tags bucket auto_fixes human_fixes zeitwerk].freeze

  def csv_row(rep, node: "", tier: "")
    require "csv"
    list = ->(fs) { fs.map { |f| "#{f["file"]}:#{f["line"]} #{f["pattern"]}" }.join("; ") }
    CSV.generate_line([rep["box"], node, tier, rep["image_tags"], rep["bucket"],
                       list.(rep["auto"]), list.(rep["human"]), rep["zeitwerk"]])
  end
  module_function :csv_row
end

if $PROGRAM_NAME == __FILE__
  mode = ARGV[0]
  opt = ->(name) { (i = ARGV.index(name)) && ARGV[i + 1] }
  case mode
  when "scan", "apply"
    root = ARGV[1]
    unless root && File.directory?(root)
      warn "usage: ruby rails8_scan.rb scan|apply <overlay rails/ dir> [--gemfile-lock PATH]"
      exit 2
    end
    puts JSON.generate(Rails8Scan.run(mode, root, opt.("--gemfile-lock")))
  when "report"
    # report <scan.json> <zeitwerk rc file> <zeitwerk log> [--box B] [--tags T] [--csv --node N --tier T]
    scan = JSON.parse(File.read(ARGV[1]))
    rep = Rails8Scan.report(scan, File.read(ARGV[2]).strip, File.read(ARGV[3]),
                            box: opt.("--box"), image_tags: opt.("--tags"))
    if ARGV.include?("--csv")
      print Rails8Scan.csv_row(rep, node: opt.("--node").to_s, tier: opt.("--tier").to_s)
    else
      puts JSON.generate(rep)
    end
  else
    warn "usage: ruby rails8_scan.rb scan|apply|report ..."
    exit 2
  end
end
