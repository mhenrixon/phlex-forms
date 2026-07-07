# frozen_string_literal: true

# A daisyui radio input.
module Forms
  class Radio < Forms::Base
    def initialize(*, name: nil, id: nil, value: nil, checked: false,
                   error: false, disabled: false, required: false, **)
      super(*, **)
      @name = name
      @id = id
      @value = value
      @checked = checked
      @error = error
      @disabled = disabled
      @required = required
    end

    def view_template
      input(**attrs)
    end

    private

    def attrs
      a = {
        type: "radio",
        name: @name,
        id: @id,
        value: @value,
        class: final_classes,
        **options.except(:class, :error)
      }
      a[:checked] = true if @checked
      a[:disabled] = true if @disabled
      a[:required] = true if @required
      a.compact
    end

    def final_classes
      error_class = "radio-error" if @error && modifiers.exclude?(:error)
      merge_classes("radio", error_class, *registered_modifier_classes, options[:class])
    end

    register_modifiers(
      primary: "radio-primary",
      secondary: "radio-secondary",
      accent: "radio-accent",
      info: "radio-info",
      success: "radio-success",
      warning: "radio-warning",
      error: "radio-error",
      neutral: "radio-neutral",
      xs: "radio-xs",
      sm: "radio-sm",
      md: "radio-md",
      lg: "radio-lg",
      xl: "radio-xl"
    )
  end
end
