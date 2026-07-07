# frozen_string_literal: true

module Forms
  # A model-bound toggle switch, delegating to DaisyUI::Toggle. Emits a hidden
  # field carrying the unchecked value so an unchecked box still submits (the
  # Rails checkbox convention).
  class Toggle < Phlex::HTML
    include PhlexForms::DelegatedField

    def initialize(*modifiers, name: nil, id: nil, value: "1", unchecked_value: "0",
                   checked: false, error: false, disabled: false, required: false, **attributes)
      @modifiers = normalize_modifiers(modifiers)
      @name = name
      @id = id
      @value = value
      @unchecked_value = unchecked_value
      @checked = checked
      @error = error
      @disabled = disabled
      @required = required
      @full_width = false
      @attributes = attributes
      super()
    end

    def view_template
      input(type: "hidden", name: @name, value: @unchecked_value) if @unchecked_value && @name
      render DaisyUI::Toggle.new(*daisy_modifiers, value: @value, **checkbox_attributes)
    end

    private

    def checkbox_attributes
      attrs = binding_attributes
      attrs[:checked] = true if @checked
      attrs
    end
  end
end
