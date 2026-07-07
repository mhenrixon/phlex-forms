# frozen_string_literal: true

module Forms
  # A model-bound range slider, delegating to DaisyUI::Range.
  class Range < Phlex::HTML
    include PhlexForms::DelegatedField

    def initialize(*modifiers, name: nil, id: nil, value: nil, min: 0, max: 100,
                   step: 1, error: false, disabled: false, full_width: true, **attributes)
      @modifiers = normalize_modifiers(modifiers)
      @name = name
      @id = id
      @value = value
      @min = min
      @max = max
      @step = step
      @error = error
      @disabled = disabled
      @required = false
      @full_width = full_width
      @attributes = attributes
      super()
    end

    def view_template
      render DaisyUI::Range.new(
        *daisy_modifiers,
        value: @value, min: @min, max: @max, step: @step,
        **binding_attributes
      )
    end
  end
end
