# frozen_string_literal: true

module Forms
  # A model-bound `<input type="file">`, delegating to DaisyUI::FileInput.
  class FileInput < Phlex::HTML
    include PhlexForms::DelegatedField

    def initialize(*modifiers, name: nil, id: nil, multiple: false, accept: nil,
                   error: false, disabled: false, required: false, full_width: true, **attributes)
      @modifiers = normalize_modifiers(modifiers)
      @name = name
      @id = id
      @multiple = multiple
      @accept = accept
      @error = error
      @disabled = disabled
      @required = required
      @full_width = full_width
      @attributes = attributes
      super()
    end

    def view_template
      attrs = binding_attributes(accept: @accept)
      attrs[:multiple] = true if @multiple
      render DaisyUI::FileInput.new(*daisy_modifiers, **attrs)
    end
  end
end
