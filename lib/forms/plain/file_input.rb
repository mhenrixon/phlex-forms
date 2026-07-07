# frozen_string_literal: true

module Forms
  module Plain
    # Bare <input type="file">.
    class FileInput < Forms::FileInput
      def view_template
        attrs = unstyled_attributes(accept: @accept)
        attrs[:multiple] = true if @multiple
        input(type: "file", **attrs)
      end
    end
  end
end
