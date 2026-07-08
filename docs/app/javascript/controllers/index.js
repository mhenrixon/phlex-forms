// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
eagerLoadControllersFrom("docs_kit/controllers", application)

// phlex-reactive's single generic client controller drives the live tag_field
// example (/docs/tag-fields). eagerLoadControllersFrom only picks up local
// *_controller.js files, so the gem's controller must be registered explicitly
// (auto-pinned by phlex-reactive's engine as "phlex/reactive/reactive_controller").
import ReactiveController from "phlex/reactive/reactive_controller"
application.register("reactive", ReactiveController)
