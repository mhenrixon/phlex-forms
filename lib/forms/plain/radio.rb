# frozen_string_literal: true

module Forms
  module Plain
    # Bare radio input.
    class Radio < Forms::Radio
      def view_template
        attrs = unstyled_attributes
        attrs[:checked] = true if @checked
        input(type: "radio", value: @value, **attrs)
      end
    end
  end
end
