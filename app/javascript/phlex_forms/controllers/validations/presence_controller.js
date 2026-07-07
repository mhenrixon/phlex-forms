import { FieldValidatorController } from "phlex_forms/controllers/validations/base_controller"
import { t } from "phlex_forms/i18n"

// Mirrors ActiveModel::Validations::PresenceValidator.
export default class extends FieldValidatorController {
  static values = {
    required: { type: Boolean, default: true },
  }

  check(value) {
    if (!this.requiredValue) return null
    return this.isBlank(value) ? t("js.forms.validations.presence.blank") : null
  }
}
