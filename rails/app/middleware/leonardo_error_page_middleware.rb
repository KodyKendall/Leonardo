class LeonardoErrorPageMiddleware
  SKIP_PATH_PREFIXES = ["/llama_bot", "/assets", "/packs", "/rails/active_storage", "/cable"].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue Exception => exception # rubocop:disable Lint/RescueException
    request = Rack::Request.new(env)
    raise exception unless handle?(request)

    render_error_page(exception, request)
  rescue Exception => render_failure # rubocop:disable Lint/RescueException
    [500, { "Content-Type" => "text/html" }, [fallback_html(exception, render_failure)]]
  end

  private

  def handle?(request)
    return false if SKIP_PATH_PREFIXES.any? { |prefix| request.path.start_with?(prefix) }

    Rails.env.development? || ENV["LEONARDO_ERROR_PAGE"] == "true"
  end

  def render_error_page(exception, request)
    payload = build_payload(exception, request)

    html = ApplicationController.render(
      template: "errors/leonardo_error",
      layout: false,
      assigns: { exception: exception, payload: payload }
    )

    [500, { "Content-Type" => "text/html; charset=utf-8" }, [html]]
  end

  def build_payload(exception, request)
    pending_migration = exception.is_a?(ActiveRecord::PendingMigrationError)
    backtrace = clean_backtrace(exception)

    {
      kind: pending_migration ? "pending_migration" : "exception",
      heading: pending_migration ? "Pending migration detected." : "Something broke in this Rails app.",
      button_label: pending_migration ? "Ask Leo to run the migration" : "Ask Leo to fix this",
      exception_class: exception.class.name,
      exception_message: exception.message.to_s,
      method: request.request_method,
      path: request.fullpath,
      backtrace: backtrace,
      command: pending_migration ? migration_command(exception, request) : exception_command(exception, request, backtrace)
    }
  end

  def exception_command(exception, request, backtrace)
    <<~TEXT
      Leo, the Rails app crashed while running inside the preview iframe.

      Your task:
      1. Diagnose the exception.
      2. Inspect the relevant files.
      3. Fix the bug.
      4. Add or update a test if appropriate.
      5. Reload and verify the page works.

      Request: #{request.request_method} #{request.fullpath}
      Exception: #{exception.class.name}: #{exception.message}

      Backtrace:
      #{backtrace.join("\n")}
    TEXT
  end

  def migration_command(exception, request)
    <<~TEXT
      Leo, the Rails app has pending migrations and won't boot.

      Please run `bin/rails db:migrate` (use your shell tool), then confirm the schema is up to date. If the migration itself fails, diagnose and fix it.

      Pending migrations detected at: #{request.request_method} #{request.fullpath}
      #{exception.message}
    TEXT
  end

  def clean_backtrace(exception)
    raw = exception.backtrace || []
    cleaned = Rails.backtrace_cleaner.clean(raw)
    cleaned = raw if cleaned.empty?
    cleaned.first(40)
  end

  def fallback_html(original, render_failure)
    <<~HTML
      <!DOCTYPE html>
      <html><head><title>Rails Error</title></head>
      <body style="font-family: system-ui; background:#2D2442; color:#f9fafb; padding:32px;">
        <h1>Something broke in this Rails app.</h1>
        <p>The Leo error page itself failed to render.</p>
        <pre style="background:#030712; padding:16px; border-radius:8px; white-space:pre-wrap;">#{escape(original.class.name)}: #{escape(original.message)}

      Render failure: #{escape(render_failure.class.name)}: #{escape(render_failure.message)}</pre>
      </body></html>
    HTML
  end

  def escape(text)
    Rack::Utils.escape_html(text.to_s)
  end
end
