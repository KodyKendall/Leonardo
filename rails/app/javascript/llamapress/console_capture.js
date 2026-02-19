// Console log capture for debugging (must be at top before any console.log calls)
// Uses sessionStorage to persist logs across page navigation
// Version 2: clears old format logs
try {
    const stored = JSON.parse(sessionStorage.getItem('_consoleLogs') || '[]');
    // Clear if old format detected (has [object Object] strings)
    const hasOldFormat = stored.some(l => l.args && l.args.some(a => a === '[object Object]'));
    window._consoleLogs = hasOldFormat ? [] : stored;
    if (hasOldFormat) sessionStorage.removeItem('_consoleLogs');
} catch { window._consoleLogs = []; }
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
});

window.addEventListener('unhandledrejection', (event) => {
    const reason = event.reason?.message || event.reason || 'Unknown rejection';
    window._consoleLogs.push({ type: 'error', args: [`Unhandled Promise: ${reason}`], timestamp: Date.now() });
    if (window._consoleLogs.length > 100) window._consoleLogs.shift();
    _saveConsoleLogs();
});
