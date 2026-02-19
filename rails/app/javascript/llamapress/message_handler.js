// Message handler for iframe communication with LlamaBot parent window
// Handles postMessage events from the Leonardo IDE

import { enableElementSelector, disableElementSelector } from "llamapress/element_selector"

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
