// Message handler for iframe communication with LlamaBot parent window
// Handles postMessage events from the Leonardo IDE

import { enableElementSelector, disableElementSelector } from "llamapress/element_selector"
import { isExecuteJsOriginAllowed } from "llamapress/execute_js_guard"
import { capPayload, MAX_PAGE_HTML_BYTES } from "llamapress/payload_caps"

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

    // Execute JavaScript in this page and reply with the (serialized) result.
    // Used by the agent's execute_browser_js tool via the LlamaBot parent window.
    if (event.data.type === 'execute-js') {
        const { id, code } = event.data;

        // Fail closed: only run arbitrary JS when the message genuinely comes from a
        // configured LlamaBot origin (see execute_js_guard.js). This guard is scoped to
        // execute-js only — every other command above is untouched.
        if (!isExecuteJsOriginAllowed(event.origin, window.LLAMABOT_ALLOWED_ORIGINS)) {
            event.source.postMessage({
                source: 'llamapress',
                type: 'js-execution-result',
                id, ok: false, result: null,
                error: `execute-js rejected: origin ${event.origin} is not in the LlamaBot allowlist`
            }, event.origin);
            return;
        }

        (async () => {
            let ok = true, serialized = null, error = null;
            try {
                // Indirect eval → runs in global scope (this file is an ES module);
                // Promise.resolve awaits promise-returning code transparently.
                const value = await Promise.resolve(window.eval(code));
                try { serialized = value === undefined ? 'undefined' : JSON.stringify(value); }
                catch { serialized = String(value); } // circular refs, DOM nodes
                if (serialized && serialized.length > 10000) serialized = serialized.slice(0, 10000) + '...[truncated]';
            } catch (e) {
                ok = false;
                error = (e && (e.stack || e.message)) ? String(e.stack || e.message) : String(e);
            }
            // Always reply, even on throw — the parent is awaiting this to resume the agent.
            event.source.postMessage({
                source: 'llamapress',
                type: 'js-execution-result',
                id, ok, result: serialized, error
            }, event.origin);
        })();
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
    // Capped: a content-heavy page (inlined transcripts, long tables) renders to
    // megabytes of markup, and this is re-sent on every single chat message.
    window.full_html = capPayload(document.documentElement.outerHTML, MAX_PAGE_HTML_BYTES);

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
