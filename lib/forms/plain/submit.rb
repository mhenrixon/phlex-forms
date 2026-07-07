# frozen_string_literal: true

module Forms
  module Plain
    # Bare <button type="submit">, reusing Forms::Submit's Create/Update label
    # derivation.
    class Submit < Forms::Submit
      def view_template(&block)
        attrs = { type: "submit", **@attributes }
        attrs[:disabled] = true if @disabled
        button(**attrs) { block ? yield : button_text }
      end
    end
  end
end
