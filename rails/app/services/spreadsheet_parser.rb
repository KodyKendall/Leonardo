# frozen_string_literal: true

# SpreadsheetParser - Robust spreadsheet/CSV parsing with automatic encoding detection
#
# Handles CSV, XLSX, XLS, and ODS files from any source with automatic
# encoding detection and fallback chain for CSVs.
#
# Usage:
#   # Basic usage - auto-detects format and encoding
#   spreadsheet = SpreadsheetParser.open(file_path)
#
#   # With ActiveStorage attachment
#   SpreadsheetParser.with_attachment(attachment) do |spreadsheet|
#     spreadsheet.row(1)
#   end
#
#   # Get data as array of hashes (specify header row)
#   data = SpreadsheetParser.parse_to_hashes(file_path, header_row: 1)
#
class SpreadsheetParser
  class ParseError < StandardError; end
  class UnsupportedFormatError < ParseError; end
  class EncodingError < ParseError; end

  # Encodings to try, in order of likelihood for business documents
  # BOM-prefixed UTF-8 first (Excel exports), then common Western encodings
  # NOTE: UTF-16 encodings removed - they will "succeed" on any file but produce garbage
  FALLBACK_ENCODINGS = [
    'bom|utf-8',           # Excel exports (Windows & Mac)
    'utf-8',               # Standard UTF-8 without BOM
    'windows-1252',        # Legacy Windows/Excel
    'iso-8859-1'           # Latin-1 (Western European)
  ].freeze

  SUPPORTED_EXTENSIONS = %w[.csv .xlsx .xlsm .xls .ods].freeze

  class << self
    # Open a spreadsheet file with automatic format and encoding detection
    #
    # @param file_path [String] Path to the file
    # @param options [Hash] Additional options
    # @option options [String] :extension Force a specific extension (e.g., '.csv')
    # @return [Roo::Base] A Roo spreadsheet object
    # @raise [UnsupportedFormatError] If file format is not supported
    # @raise [EncodingError] If CSV cannot be parsed with any known encoding
    #
    def open(file_path, options = {})
      require 'roo'

      extension = options[:extension] || detect_extension(file_path)

      validate_extension!(extension)

      if extension == '.csv'
        open_csv_with_fallback(file_path)
      else
        open_spreadsheet(file_path, extension)
      end
    end

    # Open an ActiveStorage attachment and yield the spreadsheet
    #
    # @param attachment [ActiveStorage::Attached::One] The attachment
    # @param options [Hash] Additional options passed to #open
    # @yield [Roo::Base] The opened spreadsheet
    # @return [Object] The result of the block
    #
    def with_attachment(attachment, options = {}, &block)
      attachment.open do |tempfile|
        extension = File.extname(attachment.filename.to_s).downcase
        spreadsheet = open(tempfile.path, options.merge(extension: extension))
        block.call(spreadsheet)
      end
    end

    # Parse a spreadsheet into an array of hashes
    #
    # @param file_path [String] Path to the file
    # @param header_row [Integer] Row number containing headers (1-indexed)
    # @param sheet [String, Integer] Sheet name or index (default: first sheet)
    # @param options [Hash] Additional options passed to #open
    # @return [Array<Hash>] Array of row hashes with header keys
    #
    def parse_to_hashes(file_path, header_row: 1, sheet: nil, **options)
      spreadsheet = open(file_path, **options)
      spreadsheet = spreadsheet.sheet(sheet) if sheet

      headers = extract_headers(spreadsheet, header_row)

      return [] if headers.empty?

      data_start_row = header_row + 1
      data_end_row = spreadsheet.last_row

      return [] if data_end_row.nil? || data_end_row < data_start_row

      (data_start_row..data_end_row).filter_map do |row_num|
        row_values = spreadsheet.row(row_num)
        row_hash = build_row_hash(headers, row_values)

        # Skip completely empty rows
        next if row_hash.values.all? { |v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }

        row_hash
      end
    end

    # Parse a spreadsheet into raw rows (array of arrays)
    #
    # @param file_path [String] Path to the file
    # @param options [Hash] Additional options passed to #open
    # @return [Array<Array>] Array of row arrays
    #
    def parse_to_rows(file_path, **options)
      spreadsheet = open(file_path, **options)

      return [] if spreadsheet.first_row.nil? || spreadsheet.last_row.nil?

      (spreadsheet.first_row..spreadsheet.last_row).map do |row_num|
        spreadsheet.row(row_num)
      end
    end

    # Get information about a spreadsheet without fully parsing it
    #
    # @param file_path [String] Path to the file
    # @param options [Hash] Additional options passed to #open
    # @return [Hash] Basic info about the spreadsheet
    #
    def info(file_path, **options)
      spreadsheet = open(file_path, **options)

      {
        sheets: spreadsheet.sheets,
        default_sheet: spreadsheet.default_sheet,
        first_row: spreadsheet.first_row,
        last_row: spreadsheet.last_row,
        first_column: spreadsheet.first_column,
        last_column: spreadsheet.last_column,
        row_count: spreadsheet.last_row.to_i - spreadsheet.first_row.to_i + 1
      }
    rescue StandardError => e
      { error: e.message }
    end

    private

    def detect_extension(file_path)
      File.extname(file_path).downcase
    end

    def validate_extension!(extension)
      extension = ".#{extension}" unless extension.start_with?('.')
      extension = extension.downcase

      return if SUPPORTED_EXTENSIONS.include?(extension)

      raise UnsupportedFormatError,
            "Unsupported file format: #{extension}. Supported formats: #{SUPPORTED_EXTENSIONS.join(', ')}"
    end

    def open_spreadsheet(file_path, extension)
      Roo::Spreadsheet.open(file_path, extension: extension.delete('.').to_sym)
    rescue Zip::Error => e
      raise ParseError, "Invalid or corrupted file: #{e.message}"
    rescue StandardError => e
      raise ParseError, "Failed to open spreadsheet: #{e.message}"
    end

    def open_csv_with_fallback(file_path)
      errors = []

      # First, try with the original file
      FALLBACK_ENCODINGS.each do |encoding|
        spreadsheet = try_open_csv(file_path, encoding, errors)
        return spreadsheet if spreadsheet
      end

      # If all encodings failed, try with normalized line endings
      # This handles files with mixed line endings (common in Excel exports)
      Rails.logger.debug { "[SpreadsheetParser] Trying with normalized line endings..." }
      normalized_path = normalize_csv_line_endings(file_path)

      if normalized_path
        FALLBACK_ENCODINGS.each do |encoding|
          spreadsheet = try_open_csv(normalized_path, encoding, errors, cleanup_file: true)
          return spreadsheet if spreadsheet
        end
        # Clean up temp file if all attempts failed
        File.unlink(normalized_path) if File.exist?(normalized_path)
      end

      # All encodings failed - raise with details
      error_summary = errors.map { |e| "#{e[:encoding]}: #{e[:error]}" }.join("; ")
      raise EncodingError, "Could not parse CSV with any known encoding. Tried: #{error_summary}"
    end

    def normalize_csv_line_endings(file_path)
      require 'tempfile'

      # Read file as binary to preserve all bytes
      content = File.binread(file_path)

      # Remove BOM if present (use binary string literals)
      content = content.sub("\xEF\xBB\xBF".b, "".b)

      # Normalize line endings: convert all line endings to LF
      # This handles mixed CRLF/LF situations that break CSV parsing
      # Use binary string literals to avoid encoding issues
      normalized = content.gsub("\r\n".b, "\n".b).gsub("\r".b, "\n".b)

      # Write to temp file
      temp = Tempfile.new(['normalized_csv', '.csv'])
      temp.binmode
      temp.write(normalized)
      temp.close

      temp.path
    rescue StandardError => e
      Rails.logger.debug { "[SpreadsheetParser] Failed to normalize line endings: #{e.message}" }
      nil
    end

    def try_open_csv(file_path, encoding, errors, cleanup_file: false)
      spreadsheet = Roo::Spreadsheet.open(
        file_path,
        extension: :csv,
        csv_options: build_csv_options(encoding)
      )

      # Validate parsing actually works by reading first row
      # This catches encoding errors that only surface on read
      spreadsheet.row(1)

      Rails.logger.debug { "[SpreadsheetParser] Successfully parsed CSV with encoding: #{encoding}" }

      # Note: Don't clean up the temp file here - Roo needs it to stay open
      # The temp file will be cleaned up by the OS eventually
      spreadsheet
    rescue ArgumentError,
           Encoding::InvalidByteSequenceError,
           Encoding::UndefinedConversionError,
           CSV::MalformedCSVError => e
      errors << { encoding: encoding, error: e.message }
      Rails.logger.debug { "[SpreadsheetParser] Failed with #{encoding}: #{e.message}" }
      # Clean up temp file on failure if requested
      File.unlink(file_path) if cleanup_file && File.exist?(file_path)
      nil
    end

    def build_csv_options(encoding)
      {
        encoding: encoding,
        liberal_parsing: true,        # Recover from some malformed data
        skip_blanks: false,           # Preserve row structure
        strip: true                   # Strip whitespace from values
      }
    end

    def extract_headers(spreadsheet, header_row)
      raw_headers = spreadsheet.row(header_row) || []

      raw_headers.map.with_index do |header, index|
        if header.nil? || (header.respond_to?(:empty?) && header.to_s.strip.empty?)
          "column_#{index + 1}" # Provide default name for blank headers
        else
          normalize_header(header)
        end
      end
    end

    def normalize_header(header)
      header
        .to_s
        .strip
        .gsub(/[[:space:]]+/, ' ')    # Normalize all whitespace (including NBSP) to single space
        .gsub(/[\r\n]+/, ' ')         # Replace any newlines with space
    end

    def build_row_hash(headers, row_values)
      row_values ||= []

      # Pad row_values if shorter than headers
      row_values = row_values.dup
      row_values << nil while row_values.length < headers.length

      headers.each_with_index.each_with_object({}) do |(header, index), hash|
        value = row_values[index]
        hash[header] = normalize_value(value)
      end
    end

    def normalize_value(value)
      case value
      when String
        cleaned = value.strip
        cleaned.empty? ? nil : cleaned
      when Float
        # Avoid floating point display issues for whole numbers
        value == value.to_i ? value.to_i : value
      else
        value
      end
    end
  end
end
