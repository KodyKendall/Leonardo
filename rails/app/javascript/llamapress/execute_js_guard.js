// Security guard for the execute-js postMessage command (the agent's
// execute_browser_js tool). Decides whether a message may run arbitrary JS in
// this page based on the SENDER's origin (event.origin, which the browser sets
// and a page cannot spoof).
//
// Fails closed: only origins in window.LLAMABOT_ALLOWED_ORIGINS — injected
// server-side from the LLAMABOT_ALLOWED_ORIGINS env var — or, when that is empty,
// the single origin derived below, are allowed. A malicious site that frames this
// app cannot execute code even though framing itself is permitted.

// The chat UI that serves THIS box, derived from the page's own origin.
//
// Why this exists: LLAMABOT_ALLOWED_ORIGINS is declared in Leonardo/.env.example but
// never given a value, so the injected allowlist is `[]` on every box and this guard
// rejected everything. execute_browser_js has been dead fleet-wide since it shipped —
// the origin guard landed and its producer was never configured.
//
// The derivation is the exact inverse of the rule the chat UI uses to build the iframe
// URL (`'https://rails-' + window.location.host`, LlamaBot chat/config.js:133), so it
// admits precisely the one parent that legitimately frames this page and nothing else.
// A host that is not a `rails-` subdomain is not the fleet topology, so nothing is
// derived and the guard stays closed — those boxes must configure the env var.
export function platformParentOrigin(pageOrigin) {
    try {
        const url = new URL(pageOrigin);
        if (!url.hostname.startsWith('rails-')) return null;
        url.hostname = url.hostname.slice('rails-'.length);
        return url.origin;
    } catch {
        return null;
    }
}

export function isExecuteJsOriginAllowed(origin, allowedOrigins, pageOrigin) {
    const allowed = Array.isArray(allowedOrigins) ? allowedOrigins.filter(Boolean) : [];

    // An explicit allowlist is the operator's exact intent: it wins outright, and the
    // derived default is NOT also admitted. Narrowing the list must actually narrow it.
    if (allowed.length > 0) return allowed.includes(origin);

    const derived = platformParentOrigin(
        pageOrigin !== undefined ? pageOrigin
            : (typeof window !== 'undefined' ? window.location.origin : undefined)
    );
    return derived !== null && origin === derived;
}
