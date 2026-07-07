# frozen_string_literal: true

module Forms
  # A model-bound text-like input. Thin form-binding layer over DaisyUI::Input:
  # it wires name/id/value/error/required onto the field, then delegates all
  # markup and variant handling to the daisyui gem's component (which stacks
  # positional color/size/style modifiers and passes a block straight through).
  #
  #   Forms::Input.new(:primary, :lg, type: "email", name: "user[email]")
  #
  # `w-full` is added by default so fields fill the form-control column. Pass
  # `full_width: false` for an auto-width input. For the daisyui v5 "icon/text
  # inside the field" pattern (a <label class="input"> wrapper), use
  # Forms::WrappedInput instead — this class always renders a bare <input>.
  class Input < Phlex::HTML
    # daisyui v4 `:bordered` is a no-op in v5 (the base `input` class has the
    # border); accept it silently so existing call sites don't break.
    IGNORED_MODIFIERS = %i[bordered].freeze

    def initialize(*modifiers, type: "text", name: nil, id: nil, value: nil,
                   error: false, disabled: false, required: false, full_width: true, **attributes)
      @modifiers = modifiers - IGNORED_MODIFIERS
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
      render DaisyUI::Input.new(*daisy_modifiers, **input_attributes, &)
    end

    private

    # Add :error when invalid (and no explicit color was passed) so daisyui emits
    # input-error.
    def daisy_modifiers
      return @modifiers if !@error || @modifiers.include?(:error)

      @modifiers + [:error]
    end

    def input_attributes
      attrs = {
        type: @type,
        name: @name,
        id: @id,
        value: @value.to_s,
        class: @full_width ? merge_class("w-full") : @attributes[:class],
        **@attributes.except(:error, :class)
      }
      attrs[:disabled] = true if @disabled
      attrs[:required] = true if @required
      attrs.compact
    end

    def merge_class(base)
      [base, @attributes[:class]].compact.join(" ")
    end
  end
end
