import { Controller } from "@hotwired/stimulus"

// Form-level coordinator for the validation framework. Sits on the
// <form> element and intercepts `submit` to broadcast a synchronous
// validation event to every field. Each field controller listens
// for `invalidate:forms--validations`, runs its check, and (on
// failure) appends its error to the event's `detail.errors` array.
// If anything ended up in that array, we cancel the submit and
// focus the first invalid field.
//
// The mechanism is deliberately decoupled — the form controller
// doesn't know which validators are attached to which fields. It
// just fires the event and looks at what came back. Adding a new
// validator type means adding a new field controller, nothing here.
export default class extends Controller {
  onSubmit = (event) => {
    const errors = []
    // Skip disabled controls — the browser won't submit them, so
    // validating them can incorrectly block a submit that the server
    // would happily accept.
    const fields = this.element.querySelectorAll("input:not(:disabled), textarea:not(:disabled), select:not(:disabled)")

    fields.forEach((field) => {
      const validators = (field.dataset.controller || "")
        .split(/\s+/)
        .filter((c) => c.startsWith("forms--validations--") && c !== "forms--validations--form")
      if (validators.length === 0) return

      field.dispatchEvent(
        new CustomEvent("invalidate:forms--validations", {
          detail: { errors },
        }),
      )
    })

    if (errors.length === 0) return

    event.preventDefault()
    event.stopPropagation()
    errors[0].element.focus({ preventScroll: false })
    errors[0].element.scrollIntoView({ behavior: "smooth", block: "center" })
  }
}
