# frozen_string_literal: true

# Submit button. Defaults its label from the model's persistence state
# (Create/Update <Model>) via i18n, or takes explicit text.
#
#   Submit()                 # "Create User" / "Update User"
#   Submit(:primary, :lg)    # default text, modifiers
#   Submit("Save")           # custom text
#   Submit("Save", :primary) # custom text + modifiers
module Forms
  class Submit < Forms::Base
    KNOWN_MODIFIERS = %i[
      xs sm md lg xl
      outline ghost link soft dash wide block
      primary secondary accent info success warning error neutral
      square circle active
    ].freeze

    def initialize(*args, model: nil, disabled: false, **)
      if args.first.is_a?(String) || args.first.nil?
        @text = args.first
        modifiers = args.drop(1)
      else
        @text = nil
        modifiers = args
      end
      super(*modifiers, **)
      @model = model
      @disabled = disabled
    end

    def view_template(&block)
      button(type: "submit", class: final_classes, disabled: @disabled || nil, **options.except(:class)) do
        block ? yield : button_text
      end
    end

    private

    def final_classes
      merge_classes("btn", *registered_modifier_classes, options[:class])
    end

    def button_text
      @text || default_text
    end

    def default_text
      action = persisted? ? "update" : "create"
      if (name = model_name)
        I18n.t("cmd.#{action}_model", model: name, default: I18n.t("cmd.#{action}"))
      else
        I18n.t("cmd.#{action}")
      end
    end

    def persisted?
      @model.respond_to?(:persisted?) && @model.persisted?
    end

    def model_name
      if @model.respond_to?(:model_name)
        @model.model_name.human
      elsif @model.respond_to?(:class) && @model.class.respond_to?(:model_name)
        @model.class.model_name.human
      end
    end

    register_modifiers(
      xs: "btn-xs", sm: "btn-sm", md: "btn-md", lg: "btn-lg", xl: "btn-xl",
      outline: "btn-outline", ghost: "btn-ghost", link: "btn-link",
      soft: "btn-soft", dash: "btn-dash", wide: "btn-wide", block: "btn-block",
      primary: "btn-primary", secondary: "btn-secondary", accent: "btn-accent",
      info: "btn-info", success: "btn-success", warning: "btn-warning",
      error: "btn-error", neutral: "btn-neutral",
      square: "btn-square", circle: "btn-circle", active: "btn-active"
    )
  end
end
