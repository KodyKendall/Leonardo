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

window.addEventListener("message", (event) => {
    if (event.data.source !== 'leonardo') { return; } // don't process messages from leonardo (prevents infinite loop)

    // Handle element selector commands
    if (event.data.type === 'enable-element-selector') {
        enableElementSelector();
        return;
    }

    if (event.data.type === 'disable-element-selector') {
        disableElementSelector();
        return;
    }

    // Handle clear console logs request (at start of recording)
    if (event.data.type === 'clear-console-logs') {
        window._consoleLogs = [];
        try { sessionStorage.removeItem('_consoleLogs'); } catch { /* silent */ }
        return;
    }

    // Handle console logs request
    if (event.data.type === 'get-console-logs') {
        event.source.postMessage({
            source: 'llamapress',
            type: 'console-logs',
            logs: window._consoleLogs || []
        }, event.origin);
        // Clear logs after sending
        window._consoleLogs = [];
        try { sessionStorage.removeItem('_consoleLogs'); } catch { /* silent */ }
        return;
    }

    // Ensure we have the most up-to-date HTML content
    window.full_html = document.documentElement.outerHTML;

    // Always use current browser URL for request_path (handles Turbo navigation)
    const currentPath = window.location.pathname;

    // Check if we're on a requirements page viewing a specific file
    const requirementsContainer = document.getElementById('requirements-container');
    let requirementsFilePath = null;
    let viewPathToSend = window.view_path;

    if (requirementsContainer) {
        const isFile = requirementsContainer.dataset.requirementsIsFile === 'true';
        if (isFile) {
            requirementsFilePath = requirementsContainer.dataset.requirementsFile;
            // Override view_path to show the actual requirements file being viewed
            viewPathToSend = requirementsFilePath;
        }
    }

    console.log("full_html", window.full_html);
    console.log("request_path (from URL)", currentPath);
    console.log("view_path", viewPathToSend);
    console.log("requirements_file", requirementsFilePath);
    console.log("page_loaded_at", window.page_loaded_at);

    // Validate that we have current data
    if (!currentPath || !viewPathToSend) {
        console.warn("Missing request_path or view_path - page may not be fully loaded");
    }

    //note: we can use html2canvas to feed the screenshot to Leonardo
    // html2canvas(document.body).then(canvas => {
    //     const pngData = canvas.toDataURL("image/png"); // base64 encoded PNG
    //     console.log(pngData); // "data:image/png;base64,iVBORw0K..."
    //     event.source.postMessage({
    //         source: 'llamapress',
    //         full_html: window.full_html,
    //         request_path: window.request_path,
    //         view_path: window.view_path,
    //         page_loaded_at: window.page_loaded_at,
    //         screenshot: pngData
    //     }, event.origin);
    //   });

    event.source.postMessage({
        source: 'llamapress',
        full_html: window.full_html,
        request_path: currentPath,  // Use current browser URL, not stale server-side value
        view_path: viewPathToSend,  // Use requirements file path if viewing a requirements file
        page_loaded_at: window.page_loaded_at
    }, event.origin);
});

// Element Selector functionality
let elementSelectorEnabled = false;
let elementSelectorStyles = null;
let currentHighlightedElement = null;

function enableElementSelector() {
    if (elementSelectorEnabled) return;

    elementSelectorEnabled = true;
    console.log('Element selector enabled');

    // Inject styles for hover highlighting
    elementSelectorStyles = document.createElement('style');
    elementSelectorStyles.id = 'element-selector-styles';
    elementSelectorStyles.textContent = `
        .element-selector-highlight {
            outline: 2px solid #4CAF50 !important;
            outline-offset: 2px !important;
            background-color: rgba(76, 175, 80, 0.1) !important;
            cursor: crosshair !important;
        }
        .element-selector-active * {
            cursor: crosshair !important;
        }
    `;
    document.head.appendChild(elementSelectorStyles);

    // Mark body as active
    document.body.classList.add('element-selector-active');

    // Add event listeners
    document.addEventListener('mousemove', handleElementSelectorMouseMove, true);
    document.addEventListener('click', handleElementSelectorClick, true);
}

function disableElementSelector() {
    if (!elementSelectorEnabled) return;

    elementSelectorEnabled = false;
    console.log('Element selector disabled');

    // Remove styles
    if (elementSelectorStyles) {
        elementSelectorStyles.remove();
        elementSelectorStyles = null;
    }

    // Remove body class
    document.body.classList.remove('element-selector-active');

    // Remove highlight from current element
    if (currentHighlightedElement) {
        currentHighlightedElement.classList.remove('element-selector-highlight');
        currentHighlightedElement = null;
    }

    // Remove event listeners
    document.removeEventListener('mousemove', handleElementSelectorMouseMove, true);
    document.removeEventListener('click', handleElementSelectorClick, true);
}

function handleElementSelectorMouseMove(event) {
    const target = event.target;

    if (!target || target.tagName === 'HTML' || target.tagName === 'BODY') {
        return;
    }

    // Remove highlight from previous element
    if (currentHighlightedElement && currentHighlightedElement !== target) {
        currentHighlightedElement.classList.remove('element-selector-highlight');
    }

    // Add highlight to current target
    target.classList.add('element-selector-highlight');
    currentHighlightedElement = target;
}

function handleElementSelectorClick(event) {
    event.preventDefault();
    event.stopPropagation();

    const target = event.target;

    if (!target || target.tagName === 'HTML' || target.tagName === 'BODY') {
        return;
    }

    // Extract text content for display
    let textContent = extractElementText(target);

    // Get the outerHTML for the LLM
    let outerHTML = target.outerHTML;

    // Send selected element data to parent
    window.parent.postMessage({
        source: 'element-selector',
        type: 'element-selected',
        text: textContent,
        html: outerHTML
    }, '*');

    // Visual feedback
    showSelectionFeedback(target);
}

function extractElementText(element) {
    // Get text content and clean it up
    let text = element.textContent || element.innerText || '';
    text = text.trim();

    // If text is too long, truncate it
    if (text.length > 200) {
        text = text.substring(0, 200) + '...';
    }

    // If element has no text, try to describe it
    if (!text) {
        const tagName = element.tagName.toLowerCase();
        const className = element.className ? `.${element.className.split(' ')[0]}` : '';
        const id = element.id ? `#${element.id}` : '';
        text = `${tagName}${id}${className} element`;
    }

    return text;
}

function showSelectionFeedback(element) {
    const originalOutline = element.style.outline;
    const originalBackground = element.style.backgroundColor;

    element.style.outline = '3px solid #4CAF50';
    element.style.backgroundColor = 'rgba(76, 175, 80, 0.3)';

    setTimeout(() => {
        element.style.outline = originalOutline;
        element.style.backgroundColor = originalBackground;
    }, 300);
}

// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// import "trix"
// import "@rails/actiontext"

import * as ActionCable from "@rails/actioncable"
window.ActionCable = ActionCable

console.log("application.js loaded!!");

// ============================================================================
// Navigation tracking for parent iframe (LlamaBot)
// Notifies the parent window when navigation occurs within the Rails app
// ============================================================================

// Track navigation events via Turbo
document.addEventListener('turbo:before-visit', (event) => {
    // Send the current path to parent before navigating (for back button history)
    if (window.parent !== window) {
        window.parent.postMessage({
            source: 'llamapress-navigation',
            type: 'before-navigate',
            fromPath: window.location.pathname,
            toPath: new URL(event.detail.url).pathname
        }, '*');
    }
});

// Also track when page loads (for initial load and full page refreshes)
document.addEventListener('turbo:load', () => {
    // Update view_path from meta tag (server provides fresh value on each render)
    const metaViewPath = document.querySelector('meta[name="view-path"]');
    if (metaViewPath) {
        window.view_path = metaViewPath.content;
    }

    if (window.parent !== window) {
        window.parent.postMessage({
            source: 'llamapress-navigation',
            type: 'page-loaded',
            path: window.location.pathname
        }, '*');
    }
});

// Track when Turbo finishes rendering (covers Turbo Frame and Turbo Drive navigation)
document.addEventListener('turbo:render', () => {
    // Update view_path from meta tag (server provides fresh value on each render)
    const metaViewPath = document.querySelector('meta[name="view-path"]');
    if (metaViewPath) {
        window.view_path = metaViewPath.content;
    }

    if (window.parent !== window) {
        window.parent.postMessage({
            source: 'llamapress-navigation',
            type: 'page-loaded',
            path: window.location.pathname
        }, '*');
    }
});

// Also send on popstate (browser back/forward buttons within iframe)
window.addEventListener('popstate', () => {
    if (window.parent !== window) {
        window.parent.postMessage({
            source: 'llamapress-navigation',
            type: 'page-loaded',
            path: window.location.pathname
        }, '*');
    }
});

// Track regular link clicks that might not go through Turbo
document.addEventListener('click', (event) => {
    const link = event.target.closest('a');
    if (link && link.href && !link.target && !event.defaultPrevented) {
        try {
            const url = new URL(link.href);
            // Only track same-origin navigation
            if (url.origin === window.location.origin && window.parent !== window) {
                window.parent.postMessage({
                    source: 'llamapress-navigation',
                    type: 'before-navigate',
                    fromPath: window.location.pathname,
                    toPath: url.pathname
                }, '*');
            }
        } catch (e) {
            // Invalid URL, ignore
        }
    }
}, true);

