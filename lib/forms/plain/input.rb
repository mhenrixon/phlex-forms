# frozen_string_literal: true

module Forms
  module Plain
    # Bare semantic <input>. Inherits the binding contract from Forms::Input;
    # positional variants are accepted and ignored.
    class Input < Forms::Input
      def view_template
        input(type: @type, value: @value.to_s, **unstyled_attributes)
      end
    end
  end
end
