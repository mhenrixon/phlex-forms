import { FieldValidatorController } from "phlex_forms/controllers/validations/base_controller"
import { t } from "phlex_forms/i18n"

// Mirrors ActiveModel::Validations::NumericalityValidator.
export default class extends FieldValidatorController {
  static values = {
    greaterThan: Number,
    greaterThanOrEqualTo: Number,
    lessThan: Number,
    lessThanOrEqualTo: Number,
    equalTo: Number,
    otherThan: Number,
    onlyInteger: { type: Boolean, default: false },
    odd: { type: Boolean, default: false },
    even: { type: Boolean, default: false },
  }

  check(value) {
    const raw = String(value ?? "").trim()
    if (raw === "") return null

    const number = Number(raw)
    if (Number.isNaN(number)) return t("js.forms.validations.numericality.not_a_number")

    if (this.onlyIntegerValue && !Number.isInteger(number)) {
      return t("js.forms.validations.numericality.not_an_integer")
    }
    if (this.hasGreaterThanValue && !(number > this.greaterThanValue)) {
      return t("js.forms.validations.numericality.greater_than", { count: this.greaterThanValue })
    }
    if (this.hasGreaterThanOrEqualToValue && !(number >= this.greaterThanOrEqualToValue)) {
      return t("js.forms.validations.numericality.greater_than_or_equal_to", {
        count: this.greaterThanOrEqualToValue,
      })
    }
    if (this.hasLessThanValue && !(number < this.lessThanValue)) {
      return t("js.forms.validations.numericality.less_than", { count: this.lessThanValue })
    }
    if (this.hasLessThanOrEqualToValue && !(number <= this.lessThanOrEqualToValue)) {
      return t("js.forms.validations.numericality.less_than_or_equal_to", {
        count: this.lessThanOrEqualToValue,
      })
    }
    if (this.hasEqualToValue && number !== this.equalToValue) {
      return t("js.forms.validations.numericality.equal_to", { count: this.equalToValue })
    }
    if (this.hasOtherThanValue && number === this.otherThanValue) {
      return t("js.forms.validations.numericality.other_than", { count: this.otherThanValue })
    }
    // Rails' NumericalityValidator coerces with `.to_i` before
    // checking parity, so `2.5` is treated as `2` (even). JS `%` on
    // a float diverges from that — truncate first to keep client and
    // server in agreement.
    const truncated = Math.trunc(number)
    if (this.oddValue && truncated % 2 === 0) return t("js.forms.validations.numericality.odd")
    if (this.evenValue && truncated % 2 !== 0) return t("js.forms.validations.numericality.even")
    return null
  }
}
