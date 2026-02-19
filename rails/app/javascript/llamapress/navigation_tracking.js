// Navigation tracking for parent iframe (LlamaBot)
// Notifies the parent window when navigation occurs within the Rails app

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
