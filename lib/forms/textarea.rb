# frozen_string_literal: true

# A daisyui-styled `<textarea>`.
module Forms
  class Textarea < Forms::Base
    def initialize(*, name: nil, id: nil, value: nil, error: false,
                   disabled: false, required: false, rows: 4, placeholder: nil, **)
      super(*, **)
      @name = name
      @id = id
      @value = value
      @error = error
      @disabled = disabled
      @required = required
      @rows = rows
      @placeholder = placeholder
    end

    def view_template
      textarea(**attrs) { @value }
    end

    private

    def attrs
      a = {
        name: @name,
        id: @id,
        rows: @rows,
        placeholder: @placeholder,
        class: final_classes,
        **options.except(:class, :error)
      }
      a[:disabled] = true if @disabled
      a[:required] = true if @required
      a.compact
    end

    def final_classes
      error_class = "textarea-error" if @error && modifiers.exclude?(:error)
      merge_classes("textarea w-full", error_class, *registered_modifier_classes, options[:class])
    end

    register_modifiers(
      primary: "textarea-primary",
      secondary: "textarea-secondary",
      accent: "textarea-accent",
      info: "textarea-info",
      success: "textarea-success",
      warning: "textarea-warning",
      error: "textarea-error",
      neutral: "textarea-neutral",
      ghost: "textarea-ghost",
      xs: "textarea-xs",
      sm: "textarea-sm",
      md: "textarea-md",
      lg: "textarea-lg",
      xl: "textarea-xl"
    )
  end
end
