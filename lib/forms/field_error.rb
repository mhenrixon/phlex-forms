# frozen_string_literal: true

# Inline validation error shown beneath a field.
module Forms
  class FieldError < Phlex::HTML
    def initialize(message: nil, **options)
      @message = message
      @options = options
      super()
    end

    def view_template
      return unless @message

      div(class: "label") do
        span(class: classes) { @message }
      end
    end

    private

    def classes
      PhlexForms::ClassMerge.merge("label-text-alt text-error", @options[:class])
    end
  end
end
