# frozen_string_literal: true

# Inline hint/help text shown beneath a field.
module Forms
  class FieldHint < Phlex::HTML
    def initialize(text: nil, **options)
      @text = text
      @options = options
      super()
    end

    def view_template
      return unless @text

      div(class: "label") do
        span(class: classes) { @text }
      end
    end

    private

    def classes
      PhlexForms::ClassMerge.merge("label-text-alt", @options[:class])
    end
  end
end
