// Console log capture for debugging (must be at top before any console.log calls)
// Uses sessionStorage to persist logs across page navigation
// Version 2: clears old format logs
import { parentErrorTargets } from "llamapress/error_push_targets"
import { drainEarlyErrors } from "llamapress/early_error_buffer"

try {
    const stored = JSON.parse(sessionStorage.getItem('_consoleLogs') || '[]');
    // Clear if old format detected (has [object Object] strings)
    const hasOldFormat = stored.some(l => l.args && l.args.some(a => a === '[object Object]'));
    window._consoleLogs = hasOldFormat ? [] : stored;
    if (hasOldFormat) sessionStorage.removeItem('_consoleLogs');
} catch { window._consoleLogs = []; }
// ---------------------------------------------------------------------------
// Push errors up to the LlamaBot chat (the parent frame)
// ---------------------------------------------------------------------------
// The buffer above is PULL-only, and `get-console-logs` DRAINS it (see
// message_handler.js) — so anything that reads it steals the logs from whatever
// reads next. Errors therefore get their own one-way push channel instead of a
// second reader: the chat keeps its own list, and the capture-logs button is
// unaffected.
//
// Fails silent in every direction. This runs inside a page that is already
// misbehaving, and a throw here would replace the app's real error with ours.

let _errorSeq = 0;

function _stackOf(value) {
    if (value && typeof value.stack === 'string') return value.stack.slice(0, 4000);
    return null;
}

function _pushErrorToParent(kind, message, stack) {
    try {
        if (window.parent === window) return;  // not framed — nobody to tell
        const targets = parentErrorTargets(window.location.origin, window.LLAMABOT_ALLOWED_ORIGINS);
        if (targets.length === 0) return;

        const payload = {
            source: 'llamapress',
            type: 'js-error',
            error: {
                id: `${window.page_loaded_at || 0}-${_errorSeq++}`,
                kind,
                message: String(message == null ? '' : message).slice(0, 2000),
                stack: stack || null,
                path: window.location.pathname + window.location.search,
                timestamp: Date.now()
            }
        };
        targets.forEach((origin) => {
            try { window.parent.postMessage(payload, origin); } catch { /* silent */ }
        });
    } catch { /* silent */ }
}

const originalConsoleLog = console.log;
const originalConsoleError = console.error;
const originalConsoleWarn = console.warn;

function _saveConsoleLogs() {
    try { sessionStorage.setItem('_consoleLogs', JSON.stringify(window._consoleLogs.slice(-100))); } catch { /* silent */ }
}

function _formatArg(a) {
    if (a === null) return 'null';
    if (a === undefined) return 'undefined';
    if (typeof a === 'string') return a;
    // Errors JSON.stringify to "{}" — which is exactly the argument you most
    // want to read back when debugging, so render them by hand.
    if (a instanceof Error) return `${a.name}: ${a.message}`;
    try { return JSON.stringify(a); } catch { return String(a); }
}

function _shouldSkipLog(args) {
    // Filter out noisy internal logs
    const first = args[0];
    if (typeof first === 'string' && first.startsWith('Page context updated')) return true;
    return false;
}

console.log = function(...args) {
    if (!_shouldSkipLog(args)) {
        window._consoleLogs.push({ type: 'log', args: args.map(_formatArg), timestamp: Date.now() });
        if (window._consoleLogs.length > 100) window._consoleLogs.shift();
        _saveConsoleLogs();
    }
    originalConsoleLog.apply(console, args);
};

console.error = function(...args) {
    window._consoleLogs.push({ type: 'error', args: args.map(_formatArg), timestamp: Date.now() });
    if (window._consoleLogs.length > 100) window._consoleLogs.shift();
    _saveConsoleLogs();
    // An Error passed to console.error carries the only stack we will ever get
    // for it, so look through the args rather than just formatting them.
    _pushErrorToParent('console.error', args.map(_formatArg).join(' '),
                       _stackOf(args.find((a) => a instanceof Error)));
    originalConsoleError.apply(console, args);
};

console.warn = function(...args) {
    window._consoleLogs.push({ type: 'warn', args: args.map(_formatArg), timestamp: Date.now() });
    if (window._consoleLogs.length > 100) window._consoleLogs.shift();
    _saveConsoleLogs();
    originalConsoleWarn.apply(console, args);
};

// Capture uncaught errors and unhandled promise rejections
window.addEventListener('error', (event) => {
    window._consoleLogs.push({ type: 'error', args: [`Uncaught: ${event.message} at ${event.filename}:${event.lineno}`], timestamp: Date.now() });
    if (window._consoleLogs.length > 100) window._consoleLogs.shift();
    _saveConsoleLogs();
    // Note: a script loaded cross-origin WITHOUT crossorigin+CORS collapses to a
    // bare "Script error." with no file/line here. That is a browser rule, not a
    // gap in this capture — our own asset-pipeline scripts are same-origin.
    _pushErrorToParent('uncaught', `${event.message} at ${event.filename}:${event.lineno}`,
                       _stackOf(event.error));
});

window.addEventListener('unhandledrejection', (event) => {
    const reason = event.reason?.message || event.reason || 'Unknown rejection';
    window._consoleLogs.push({ type: 'error', args: [`Unhandled Promise: ${reason}`], timestamp: Date.now() });
    if (window._consoleLogs.length > 100) window._consoleLogs.shift();
    _saveConsoleLogs();
    _pushErrorToParent('unhandled-rejection', String(reason), _stackOf(event.reason));
});

// Replay anything that blew up BEFORE this module existed. Modules are deferred,
// so an inline <script> in the body that throws during page load never reached
// the listeners above — the layout head buffers those for us. Drained last, so
// the real listeners are already installed and there is no gap in between.
drainEarlyErrors(window).forEach((e) => {
    window._consoleLogs.push({ type: 'error', args: [e.message], timestamp: Date.now() });
    if (window._consoleLogs.length > 100) window._consoleLogs.shift();
    _pushErrorToParent(e.kind, e.message, e.stack);
});
_saveConsoleLogs();
