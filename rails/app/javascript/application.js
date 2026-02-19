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

console.log("application.js loaded!!");
