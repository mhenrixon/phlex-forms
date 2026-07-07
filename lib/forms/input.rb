# frozen_string_literal: true

module Forms
  # A model-bound text-like input. Thin form-binding layer over DaisyUI::Input:
  # it wires name/id/value/error/required onto the field, then delegates all
  # markup and variant handling to the daisyui gem's component (which stacks
  # positional color/size/style modifiers and passes a block straight through).
  #
  #   Forms::Input.new(:primary, :lg, type: "email", name: "user[email]")
  #
  # `w-full` is added by default. For the daisyui v5 "icon/text inside the field"
  # pattern (a <label class="input"> wrapper), use Forms::WrappedInput.
  class Input < Phlex::HTML
    include PhlexForms::DelegatedField

    def initialize(*modifiers, type: "text", name: nil, id: nil, value: nil,
                   error: false, disabled: false, required: false, full_width: true, **attributes)
      @modifiers = normalize_modifiers(modifiers)
      @type = type
      @name = name
      @id = id
      @value = value
      @error = error
      @disabled = disabled
      @required = required
      @full_width = full_width
      @attributes = attributes
      super()
    end

    def view_template(&)
      render DaisyUI::Input.new(*daisy_modifiers, type: @type, value: @value.to_s, **binding_attributes, &)
    end
  end
end
