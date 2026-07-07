# frozen_string_literal: true

# Auto-pins the gem's bundled Stimulus controllers for importmap-rails consumers.
# Register them in the host app (lazy loading recommended):
#
#   // app/javascript/controllers/index.js
#   import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
#   lazyLoadControllersFrom("phlex_forms/controllers", application)
#
# The `choices` controller expects the `choices.js` package to be available in
# the host importmap (peer dependency); document it in the host README.
pin_all_from PhlexForms::Engine.root.join("app/javascript/phlex_forms/controllers"),
  under: "phlex_forms/controllers",
  to: "phlex_forms/controllers"

# The client-side validation controllers import the gem's own i18n helper and
# bundled messages; pin those modules so importmap can resolve them.
pin "phlex_forms/i18n",
  to: "phlex_forms/i18n.js"
pin "phlex_forms/messages",
  to: "phlex_forms/messages.js"
