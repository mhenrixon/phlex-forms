# frozen_string_literal: true

module Forms
  module Plain
    # Row without grid classes: a bare <div> with a data hook so host CSS can
    # lay it out (columns: is accepted and ignored).
    class Row < Forms::Row
      def view_template(&)
        div(data: { form_row: true }, class: @options[:class], **@options.except(:class), &)
      end
    end
  end
end
