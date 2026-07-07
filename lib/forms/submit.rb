# frozen_string_literal: true

module Forms
  # Submit button, delegating markup and variants to DaisyUI::Button. Defaults its
  # label from the model's persistence state (Create/Update <Model>) via i18n, or
  # takes explicit text.
  #
  #   Submit()                 # "Create User" / "Update User"
  #   Submit(:primary, :lg)    # default text, modifiers
  #   Submit("Save")           # custom text
  #   Submit("Save", :primary) # custom text + modifiers
  class Submit < Phlex::HTML
    def initialize(*args, model: nil, disabled: false, **attributes)
      if args.first.is_a?(String) || args.first.nil?
        @text = args.first
        @modifiers = args.drop(1)
      else
        @text = nil
        @modifiers = args
      end
      @model = model
      @disabled = disabled
      @attributes = attributes
      super()
    end

    def view_template(&block)
      attrs = { type: "submit", **@attributes }
      attrs[:disabled] = true if @disabled
      render DaisyUI::Button.new(*@modifiers, **attrs) do
        block ? yield : button_text
      end
    end

    private

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
  end
end
