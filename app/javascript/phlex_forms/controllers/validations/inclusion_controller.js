import { FieldValidatorController } from "phlex_forms/controllers/validations/base_controller"
import { t } from "phlex_forms/i18n"

// Mirrors ActiveModel::Validations::InclusionValidator.
export default class extends FieldValidatorController {
  static values = {
    in: String,
  }

  check(value) {
    if (!this.hasInValue) return null
    try {
      const list = JSON.parse(this.inValue)
      return list.map(String).includes(String(value ?? "")) ? null : t("js.forms.validations.inclusion.inclusion")
    } catch (_e) {
      return null
    }
  }
}
