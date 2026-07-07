# frozen_string_literal: true

module Forms
  module Plain
    # Inline validation error: no styling classes, stable hooks only
    # (role="alert" + data-field-error).
    class FieldError < Forms::FieldError
      def view_template
        return unless @message

        p(role: "alert", data: { field_error: true }, **@options) { @message }
      end
    end
  end
end
