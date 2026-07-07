# frozen_string_literal: true

module Forms
  # A model-bound textarea. Thin form-binding layer over DaisyUI::Textarea.
  class Textarea < Phlex::HTML
    include PhlexForms::DelegatedField

    def initialize(*modifiers, name: nil, id: nil, value: nil, error: false,
                   disabled: false, required: false, rows: 4, full_width: true, **attributes)
      @modifiers = normalize_modifiers(modifiers)
      @name = name
      @id = id
      @value = value
      @error = error
      @disabled = disabled
      @required = required
      @rows = rows
      @full_width = full_width
      @attributes = attributes
      super()
    end

    def view_template
      render DaisyUI::Textarea.new(*daisy_modifiers, rows: @rows, **binding_attributes) { @value }
    end
  end
end
