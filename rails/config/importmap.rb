# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# LlamaPress helpers - console capture, element selector, message handling, navigation tracking
# These are extracted from application.js so downstream repos can override individual helpers
# by creating their own files at rails/app/javascript/llamapress/<helper_name>.js
pin_all_from "app/javascript/llamapress", under: "llamapress"

pin "@rails/actioncable", to: "@rails--actioncable.js" # @8.0.201
pin "trix"
pin "sortablejs", to: "sortablejs.js", preload: true
pin "@rails/actiontext", to: "actiontext.esm.js"
