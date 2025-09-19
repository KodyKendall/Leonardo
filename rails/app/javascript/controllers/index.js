// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Load standard controllers
eagerLoadControllersFrom("controllers", application)

// Load prototype controllers with "prototypes--" namespace
const protoContext = require.context("./prototypes", true, /_controller\.js$/)

protoContext.keys().forEach((key) => {
  const identifier = "prototypes--" + key
    .replace("./", "")                // remove "./"
    .replace("_controller.js", "")    // strip filename suffix
    .replace(/\//g, "--")             // turn nested folders into Stimulus namespace
  application.register(identifier, protoContext(key).default)
})
