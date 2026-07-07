# frozen_string_literal: true

module Forms
  module Plain
    # Bare <textarea>. Also fills the :rich_textarea theme role (documented
    # degradation — rich text needs an editor integration the plain theme
    # doesn't ship), so it swallows the rich-text-only value handling.
    class Textarea < Forms::Textarea
      def view_template
        textarea(rows: @rows, **unstyled_attributes) { @value }
      end
    end
  end
end
