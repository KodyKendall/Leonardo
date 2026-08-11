// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// import "trix"
// import "@rails/actiontext"

import * as ActionCable from "@rails/actioncable"
window.ActionCable = ActionCable

// LlamaPress helpers - downstream can override by creating their own files at these paths
import "llamapress/console_capture"
import "llamapress/element_selector"
import "llamapress/message_handler"
import "llamapress/navigation_tracking"
import "llamapress/screenshot_annotator"
import "llamapress/video_recorder"
import "llamapress/feedback_bubble"
import "llamapress/feedback_element_highlight"

// Required for the app to be installable to a phone's home screen: Chromium won't
// fire beforeinstallprompt without a registered worker. Failure is expected and
// non-fatal (insecure origins, private windows), so it must never break boot.
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker.js").catch(() => {})
  })
}

console.log("application.js loaded!!");
