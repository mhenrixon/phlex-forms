# frozen_string_literal: true

# A form label. Standalone by default: renders `<label><span class="label">…</span></label>`
# with an optional required marker. A block, when given, is yielded directly
# inside the `<label>` so checkboxes/toggles can be nested as direct children.
module Forms
  class Label < Forms::Base
    def initialize(*, text: nil, for: nil, required: false, **)
      super(*, **)
      @text = text
      @for = grab(for:)
      @required = required
    end

    def view_template(&block)
      label(for: @for, class: label_classes.presence, **options.except(:class)) do
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

    private

    def label_classes
      merge_classes(*registered_modifier_classes, options[:class])
    end

    register_modifiers(
      top: "label-top",
      bottom: "label-bottom",
      start: "label-start",
      end: "label-end",
      clickable: "cursor-pointer",
      alt: "label-text-alt"
    )
  end
end
