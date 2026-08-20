// Where this page is allowed to push JavaScript errors when it is framed by the
// LlamaBot chat (see console_capture.js).
//
// postMessage MUST be given a concrete targetOrigin. '*' would hand every error
// message — which can carry record ids, paths and user-entered text out of a
// stack trace — to whatever site happens to be framing this app. So we compute
// an explicit list instead, and post once per entry: the browser silently drops
// a message whose targetOrigin does not match the real parent, so listing an
// origin that is not the parent leaks nothing.
//
// Two sources, unioned:
//
//   1. LLAMABOT_ALLOWED_ORIGINS — the operator-configured allowlist (same one
//      execute_js_guard.js uses). Authoritative when set.
//   2. The DERIVED chat origin — this app's own origin with the leading
//      "rails-" host prefix stripped, mirroring LlamaBot's getRailsUrl(). This
//      exists because the env var is unset on plenty of boxes, and a debugging
//      aid that silently does nothing on most of the fleet is worse than no
//      aid at all. The derivation only ever names our own chat host.
//
// Pure function, no DOM: the caller passes location.origin so this stays testable.

/** "https://rails-foo.example" -> "https://foo.example"; localhost:3000 -> :8000. */
export function deriveChatOrigin(currentOrigin) {
    if (!currentOrigin || typeof currentOrigin !== 'string') return null;

    let url;
    try { url = new URL(currentOrigin); } catch { return null; }

    // Dev: Rails on :3000 is framed by the chat on :8000, same host.
    if (url.port === '3000') return `${url.protocol}//${url.hostname}:8000`;

    // Deployed: rails-<box>.llamapress.ai is framed by <box>.llamapress.ai.
    if (url.hostname.startsWith('rails-')) {
        const chatHost = url.hostname.slice('rails-'.length);
        return `${url.protocol}//${chatHost}${url.port ? ':' + url.port : ''}`;
    }

    // Anything else (custom domain, no known pairing) — no safe derivation.
    return null;
}

/**
 * @param {string} currentOrigin - location.origin of this page
 * @param {string[]} allowedOrigins - window.LLAMABOT_ALLOWED_ORIGINS
 * @returns {string[]} deduped concrete origins to postMessage errors to
 */
export function parentErrorTargets(currentOrigin, allowedOrigins) {
    const targets = [];
    const push = (o) => { if (o && !targets.includes(o)) targets.push(o); };

    if (Array.isArray(allowedOrigins)) {
        allowedOrigins.forEach((o) => { if (typeof o === 'string' && o) push(o.trim()); });
    }
    push(deriveChatOrigin(currentOrigin));

    // Never post back to ourselves — that is the un-framed case, not a parent.
    return targets.filter((o) => o !== currentOrigin);
}
