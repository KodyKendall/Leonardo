// Decides whether a captured error belongs ENTIRELY to a browser extension
// (MetaMask, password managers, request interceptors) rather than to this app.
//
// Extensions inject their scripts into the MAIN WORLD of the document, so they
// share `window` with the app and their throws fire the app's own error
// listeners in console_capture.js. Nothing about the event says whose code
// threw: the frame really is the app's origin, so an origin check cannot help.
// The only provenance we have is the URL scheme in the stack frames (and
// `event.filename` for uncaught errors).
//
// The rule is deliberately NOT "contains chrome-extension://". An extension that
// monkey-patches window.fetch ends up as the TOP frame of a stack whose lower
// frames are the app's own code, and that error is a real app problem. So: drop
// only when at least one frame is extension code AND no frame comes from an
// http(s) origin. Frames with no URL at all (native, <anonymous>, eval) do not
// count either way, which keeps a bare "Script error." — a browser CORS rule,
// not an extension — visible.

const EXTENSION_SCHEME = /\b(?:chrome|moz|safari-web|safari|ms-browser)-extension:\/\//;
const HTTP_URL = /\bhttps?:\/\/[^\s)]+/g;

/**
 * @param {{message?: string, stack?: string, filename?: string}} [error]
 * @returns {boolean} true when every located frame is extension code
 */
export function isExtensionOnly({ message, stack, filename } = {}) {
    try {
        const text = [filename, message, stack].filter(Boolean).join('\n');
        if (!EXTENSION_SCHEME.test(text)) return false;
        return (text.match(HTTP_URL) || []).length === 0;
    } catch {
        return false;  // never hide a real error because this threw
    }
}
