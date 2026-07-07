# frozen_string_literal: true

module Forms
  module Plain
    # Bare checkbox, keeping the hidden unchecked-value field (that's binding
    # logic, not styling). Also fills the :toggle theme role — a toggle is a
    # styled checkbox.
    class Checkbox < Forms::Checkbox
      def view_template
        input(type: "hidden", name: @name, value: @unchecked_value) if @unchecked_value && @name
        attrs = unstyled_attributes
        attrs[:checked] = true if @checked
        input(type: "checkbox", value: @value, **attrs)
      end
    end
  end
end
