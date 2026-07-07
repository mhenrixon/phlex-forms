# frozen_string_literal: true

module Forms
  module Plain
    # Inline hint text with a data-field-hint hook, no styling classes.
    class FieldHint < Forms::FieldHint
      def view_template
        return unless @text

        p(data: { field_hint: true }, **@options) { @text }
      end
    end
  end
end
