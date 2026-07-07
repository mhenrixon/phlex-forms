# frozen_string_literal: true

module Forms
  module Plain
    # Bare <label>, with the required marker as a semantic <abbr>.
    class Label < Forms::Label
      def view_template(&block)
        label(for: @for, **@attributes) do
          if block
            yield
          elsif @text
            plain @text
            abbr(title: "required") { "*" } if @required
          end
        end
      end
    end
  end
end
