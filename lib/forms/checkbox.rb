# frozen_string_literal: true

# A daisyui checkbox. Emits a hidden field carrying the unchecked value so an
# unchecked box still submits (the Rails checkbox convention).
module Forms
  class Checkbox < Forms::Base
    def initialize(*, name: nil, id: nil, value: "1", unchecked_value: "0",
                   checked: false, error: false, disabled: false, required: false, **)
      super(*, **)
      @name = name
      @id = id
      @value = value
      @unchecked_value = unchecked_value
      @checked = checked
      @error = error
      @disabled = disabled
      @required = required
    end

    def view_template
      input(type: "hidden", name: @name, value: @unchecked_value) if @unchecked_value && @name
      input(**attrs)
    end

    private

    def attrs
      a = {
        type: "checkbox",
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
      error_class = "checkbox-error" if @error && modifiers.exclude?(:error)
      merge_classes("checkbox", error_class, *registered_modifier_classes, options[:class])
    end

    register_modifiers(
      primary: "checkbox-primary",
      secondary: "checkbox-secondary",
      accent: "checkbox-accent",
      info: "checkbox-info",
      success: "checkbox-success",
      warning: "checkbox-warning",
      error: "checkbox-error",
      neutral: "checkbox-neutral",
      xs: "checkbox-xs",
      sm: "checkbox-sm",
      md: "checkbox-md",
      lg: "checkbox-lg",
      xl: "checkbox-xl"
    )
  end
end
