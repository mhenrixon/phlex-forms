# frozen_string_literal: true

module Forms
  # A model-bound radio input, delegating to DaisyUI::Radio.
  class Radio < Phlex::HTML
    include PhlexForms::DelegatedField

    def initialize(*modifiers, name: nil, id: nil, value: nil, checked: false,
                   error: false, disabled: false, required: false, **attributes)
      @modifiers = normalize_modifiers(modifiers)
      @name = name
      @id = id
      @value = value
      @checked = checked
      @error = error
      @disabled = disabled
      @required = required
      @full_width = false
      @attributes = attributes
      super()
    end

    def view_template
      attrs = binding_attributes
      attrs[:checked] = true if @checked
      render DaisyUI::Radio.new(*daisy_modifiers, value: @value, **attrs)
    end
  end
end
