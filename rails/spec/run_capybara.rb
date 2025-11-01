# spec/run_capybara.rb
require "json"
require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    browser_options: { "no-sandbox": nil, "disable-gpu": nil },
    process_timeout: ENV.fetch("CUPRITE_TIMEOUT", "20").to_i
  )
end

session = Capybara::Session.new(:cuprite)
driver  = session.driver

# Preload a console/error logger into every new document BEFORE app JS runs
preload_js = <<~JS
  (function(){
    if (window.__agent__) return;
    window.__agent__ = { logs: [], errors: [] };

    function safeToString(v){
      try {
        if (v && v.stack) return String(v.stack);
        if (typeof v === "object") return JSON.stringify(v);
        return String(v);
      } catch (_) { return String(v); }
    }
    function store(level, args){
      try {
        var msg = Array.from(args).map(safeToString).join(" ");
        window.__agent__.logs.push({ level: level, text: msg, ts: Date.now() });
      } catch (_) {}
    }

    ["log","info","warn","error"].forEach(function(level){
      var orig = console[level];
      console[level] = function(){ store(level, arguments); return orig.apply(console, arguments); };
    });

    window.addEventListener("error", function(e){
      window.__agent__.errors.push({
        type: "error", message: e.message, source: e.filename, line: e.lineno, col: e.colno, ts: Date.now()
      });
      store("error", [e.message]);
    });

    window.addEventListener("unhandledrejection", function(e){
      var r = e && e.reason;
      var msg = (r && (r.message || r.toString())) || "unhandledrejection";
      window.__agent__.errors.push({ type: "unhandledrejection", message: msg, ts: Date.now() });
      store("error", ["UnhandledRejection:", msg]);
    });
  })();
JS

# Force browser initialization by visiting about:blank
session.visit("about:blank")

# Send CDP command: add script evaluated on every new document
# Cuprite's browser gives us direct access to the Ferrum browser
browser = driver.browser
page = browser.page

# Enable Page and Runtime domains, then add our preload script
page.command("Page.enable")
page.command("Runtime.enable")
page.command("Page.addScriptToEvaluateOnNewDocument", source: preload_js)

code = ARGV.join(" ")
if code.strip.empty?
  warn "Usage: bin/rails runner spec/run_capybara.rb '<capybara ruby code>'"
  exit 2
end

begin
  result = eval(code, binding)

  # Pull page state / logs synchronously before we exit
  state = session.evaluate_async_script(<<~JS)
    (function(done){
      try {
        done({
          url: location.href,
          title: document.title,
          logs: (window.__agent__ && window.__agent__.logs) || [],
          errors: (window.__agent__ && window.__agent__.errors) || []
        });
      } catch(e) { done({url:null,title:null,logs:[],errors:[String(e)]}); }
    })(arguments[0]);
  JS

  out = { ok: true, result: result, state: state }
  puts JSON.generate(out)
rescue => e
  puts JSON.generate({ ok: false, error: { klass: e.class.name, message: e.message, backtrace: e.backtrace&.first(5) } })
  exit 1
end
