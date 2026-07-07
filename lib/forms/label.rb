# frozen_string_literal: true

module Forms
  # A standalone form label: `<label for><span class="label">text</span></label>`
  # with an optional required marker. A block, when given, is yielded directly
  # inside the `<label>` so checkboxes/toggles can nest as direct children.
  #
  # For the daisyui v5 "text/icon inside the field" wrapper (<label class="input">
  # {span.label}{input}), use Forms::WrappedInput instead.
  class Label < Phlex::HTML
    def initialize(text: nil, for: nil, required: false, **attributes)
      @text = text
      @for = grab(for:)
      @required = required
      @attributes = attributes
      super()
    end

    def view_template(&block)
      label(for: @for, class: @attributes[:class], **@attributes.except(:class)) do
        if block
          yield
        elsif @text
          span(class: "label") do
            plain @text
            span(class: "text-error ml-1") { "*" } if @required
          end
        end
      end
    end
  end
end
