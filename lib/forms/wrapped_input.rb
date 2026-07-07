# frozen_string_literal: true

module Forms
  # The daisyui v5 "text/icon inside the field" pattern: a `<label class="input">`
  # wrapper that owns the visual styling, with leading/trailing content (icons,
  # kbd hints, a text prefix) rendered as siblings of a bare `<input>`.
  #
  #   f.field(:search).wrapped_input(:primary) do
  #     _lucide("search")             # or any leading content
  #   end
  #
  # The yielded block renders *before* the input (leading slot); pass `trailing:`
  # for content after it. The input itself is bare (no `input` class) since the
  # wrapping label carries it — this is the daisyui v5 convention.
  class WrappedInput < Phlex::HTML
    include PhlexForms::DelegatedField

    def initialize(*modifiers, type: "text", name: nil, id: nil, value: nil,
                   placeholder: nil, error: false, disabled: false, required: false,
                   trailing: nil, **attributes)
      @modifiers = normalize_modifiers(modifiers)
      @type = type
      @name = name
      @id = id
      @value = value
      @placeholder = placeholder
      @error = error
      @disabled = disabled
      @required = required
      @trailing = trailing
      @full_width = true
      @attributes = attributes
      super()
    end

    def view_template(&leading)
      render DaisyUI::Label.new(:input, *daisy_modifiers, class: width_class) do
        leading&.call
        input(**bare_input_attributes)
        render_trailing
      end
    end

    private

    def bare_input_attributes
      attrs = {
        type: @type,
        name: @name,
        id: @id,
        value: @value.to_s,
        placeholder: @placeholder,
        class: "grow",
        **@attributes.except(:error, :value, :class)
      }
      attrs[:disabled] = true if @disabled
      attrs[:required] = true if @required
      attrs.compact
    end

    def render_trailing
      return unless @trailing

      @trailing.respond_to?(:call) ? @trailing.call : plain(@trailing)
    end
  end
end
