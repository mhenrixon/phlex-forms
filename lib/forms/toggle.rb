# frozen_string_literal: true

# A daisyui toggle switch. Emits a hidden field carrying the unchecked value so
# an unchecked box still submits (the Rails checkbox convention).
module Forms
  class Toggle < Forms::Base
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
      error_class = "toggle-error" if @error && modifiers.exclude?(:error)
      merge_classes("toggle", error_class, *registered_modifier_classes, options[:class])
    end

    register_modifiers(
      primary: "toggle-primary",
      secondary: "toggle-secondary",
      accent: "toggle-accent",
      info: "toggle-info",
      success: "toggle-success",
      warning: "toggle-warning",
      error: "toggle-error",
      neutral: "toggle-neutral",
      xs: "toggle-xs",
      sm: "toggle-sm",
      md: "toggle-md",
      lg: "toggle-lg",
      xl: "toggle-xl"
    )
  end
end
