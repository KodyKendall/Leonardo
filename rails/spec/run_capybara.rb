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

AUTO_LOGIN = ENV.fetch("CAPYBARA_AUTO_LOGIN", "true") == "true"
LOGIN_EMAIL = ENV.fetch("CAPYBARA_USER_EMAIL", "kody@llamapress.ai")
LOGIN_PASSWORD = ENV.fetch("CAPYBARA_USER_PASSWORD", "123456")
BASE_URL = ENV.fetch("CAPYBARA_BASE_URL", ENV.fetch("LLAMAPRESS_API_URL", "http://llamapress:3000"))

Capybara.app_host = BASE_URL

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

def perform_login(session, email, password)
  session.visit("/users/sign_in")
  # Wait for the page to load and form to be present
  session.find("#user_email", wait: 10)
  session.fill_in "user_email", with: email
  session.fill_in "user_password", with: password
  session.click_button "Log in"
  # Wait for redirect after login
  sleep 1
end

# Helper to normalize URLs - converts localhost:3000 to the correct BASE_URL
def normalize_url(url)
  return url if url.nil? || url.start_with?("/")
  url.gsub(%r{https?://localhost:3000}, BASE_URL)
     .gsub(%r{https?://127\.0\.0\.1:3000}, BASE_URL)
end

# Wrap session.visit to auto-normalize URLs
original_visit = session.method(:visit)
session.define_singleton_method(:visit) do |url|
  normalized = normalize_url(url)
  original_visit.call(normalized)
end

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

if AUTO_LOGIN
  perform_login(session, LOGIN_EMAIL, LOGIN_PASSWORD)
end

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
