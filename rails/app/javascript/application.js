window.addEventListener("message", (event) => {
    if (event.data.source !== 'leonardo') { return; } // don't process messages from leonardo (prevents infinite loop)
    
    console.log("here is the message", event);
    
    // Ensure we have the most up-to-date HTML content
    window.full_html = document.documentElement.outerHTML;
    
    console.log("full_html", window.full_html);
    console.log("request_path", window.request_path);
    console.log("view_path", window.view_path);
    console.log("page_loaded_at", window.page_loaded_at);

    // Validate that we have current data
    if (!window.request_path || !window.view_path) {
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
        request_path: window.request_path, 
        view_path: window.view_path,
        page_loaded_at: window.page_loaded_at
    }, event.origin);
});

// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// import "trix"
// import "@rails/actiontext"

import * as ActionCable from "@rails/actioncable"
window.ActionCable = ActionCable

console.log("application.js loaded!!");

