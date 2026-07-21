// Security guard for the execute-js postMessage command (the agent's
// execute_browser_js tool). Decides whether a message may run arbitrary JS in
// this page based on the SENDER's origin (event.origin, which the browser sets
// and a page cannot spoof).
//
// Fails closed: only origins explicitly listed in window.LLAMABOT_ALLOWED_ORIGINS
// — injected server-side from the LLAMABOT_ALLOWED_ORIGINS env var — are allowed.
// An unset/empty/non-array allowlist rejects everything, so a malicious site that
// frames this app cannot execute code even though framing itself is permitted.
export function isExecuteJsOriginAllowed(origin, allowedOrigins) {
    const allowed = Array.isArray(allowedOrigins) ? allowedOrigins : [];
    return allowed.includes(origin);
}
