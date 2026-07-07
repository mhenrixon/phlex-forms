# frozen_string_literal: true

# A text-like `<input>` (text, email, password, number, date, url, tel, ...).
# daisyui v5 styles the input element directly with the `input` class.
module Forms
  class Input < Forms::Base
    def initialize(*, type: "text", name: nil, id: nil, value: nil,
                   error: false, disabled: false, required: false, placeholder: nil, **)
      super(*, **)
      @type = type
      @name = name
      @id = id
      @value = value
      @error = error
      @disabled = disabled
      @required = required
      @placeholder = placeholder
    end

    def view_template
      input(**input_attributes)
    end

    private

    def input_attributes
      attrs = {
        type: @type,
        name: @name,
        id: @id,
        value: @value.to_s,
        placeholder: @placeholder,
        class: final_classes,
        **options.except(:class, :error)
      }
      attrs[:disabled] = true if @disabled
      attrs[:required] = true if @required
      attrs.compact
    end

    def final_classes
      # `:bare` skips the daisyui `input` wrapper so the field can nest inside a
      # parent `<label class="input">` (the daisyui "input with icon" pattern).
      parts =
        if modifiers.include?(:bare)
          registered_modifier_classes
        else
          error_class = "input-error" if @error && modifiers.exclude?(:error)
          ["input w-full", error_class, *registered_modifier_classes]
        end

      merge_classes(*parts, options[:class])
    end

    register_modifiers(
      primary: "input-primary",
      secondary: "input-secondary",
      accent: "input-accent",
      info: "input-info",
      success: "input-success",
      warning: "input-warning",
      error: "input-error",
      neutral: "input-neutral",
      ghost: "input-ghost",
      bordered: "input-bordered",
      xs: "input-xs",
      sm: "input-sm",
      md: "input-md",
      lg: "input-lg",
      xl: "input-xl"
    )
  end
end
