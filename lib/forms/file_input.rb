# frozen_string_literal: true

# A daisyui-styled `<input type="file">`.
module Forms
  class FileInput < Forms::Base
    def initialize(*, name: nil, id: nil, multiple: false, accept: nil,
                   error: false, disabled: false, required: false, **)
      super(*, **)
      @name = name
      @id = id
      @multiple = multiple
      @accept = accept
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
        type: "file",
        name: @name,
        id: @id,
        accept: @accept,
        class: final_classes,
        **options.except(:class, :value, :error)
      }
      a[:multiple] = true if @multiple
      a[:disabled] = true if @disabled
      a[:required] = true if @required
      a.compact
    end

    def final_classes
      error_class = "file-input-error" if @error && modifiers.exclude?(:error)
      merge_classes("file-input w-full", error_class, *registered_modifier_classes, options[:class])
    end

    register_modifiers(
      primary: "file-input-primary",
      secondary: "file-input-secondary",
      accent: "file-input-accent",
      info: "file-input-info",
      success: "file-input-success",
      warning: "file-input-warning",
      error: "file-input-error",
      neutral: "file-input-neutral",
      ghost: "file-input-ghost",
      xs: "file-input-xs",
      sm: "file-input-sm",
      md: "file-input-md",
      lg: "file-input-lg",
      xl: "file-input-xl"
    )
  end
end
