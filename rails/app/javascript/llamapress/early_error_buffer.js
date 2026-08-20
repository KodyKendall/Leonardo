// Drains the earliest-possible error buffer into console_capture's format.
//
// Why this exists: console_capture.js is loaded through the importmap as an ES
// MODULE, and modules are deferred — they execute only after the document has
// been parsed. So an inline <script> in the body that throws during page load
// blows up BEFORE console_capture's `error` listener exists, and was recorded
// nowhere at all. That is the most important error a user ever wants to report:
// "I loaded the page and it's broken."
//
// The fix is a tiny classic <script> in the layout head (rendered before the
// importmap tags) that does nothing but stash such errors on
// `window.__llamapressEarlyErrors`. This module is the other half: console_capture
// drains that buffer once it loads, then sets it to null, which is also the
// signal the early listeners use to stand down.

/** Uncaught errors carry file/line separately; fold them into one message. */
function _messageOf(raw) {
    if (raw.filename) return `${raw.message} at ${raw.filename}:${raw.lineno}`;
    return String(raw.message);
}

/**
 * Read and clear the early buffer.
 *
 * @param {Window} win - the window holding __llamapressEarlyErrors
 * @returns {{kind: string, message: string, stack: string|null}[]}
 */
export function drainEarlyErrors(win) {
    if (!win) return [];

    const raw = win.__llamapressEarlyErrors;
    // Null (not delete) — the early listeners check for this exact value to know
    // console_capture has taken over, so they stop double-recording.
    win.__llamapressEarlyErrors = null;

    if (!Array.isArray(raw)) return [];

    return raw
        .filter((e) => e && e.message != null && e.message !== '')
        .map((e) => ({
            kind: e.kind === 'unhandled-rejection' ? 'unhandled-rejection' : 'uncaught',
            message: _messageOf(e),
            stack: typeof e.stack === 'string' ? e.stack.slice(0, 4000) : null
        }));
}
