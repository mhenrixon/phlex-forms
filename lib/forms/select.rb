# frozen_string_literal: true

module Forms
  # A model-bound native `<select>`. Delegates the element + variants to
  # DaisyUI::Select (daisyui v5 puts the `select` class on the element itself)
  # and renders the options from `choices` inside its block.
  class Select < Phlex::HTML
    include PhlexForms::DelegatedField

    def initialize(*modifiers, name: nil, id: nil, choices: [], selected: nil,
                   include_blank: false, prompt: nil, error: false, disabled: false,
                   required: false, full_width: true, **attributes)
      @modifiers = normalize_modifiers(modifiers)
      @name = name
      @id = id
      @choices = choices
      @selected = selected
      @include_blank = include_blank
      @prompt = prompt
      @error = error
      @disabled = disabled
      @required = required
      @full_width = full_width
      @attributes = attributes
      super()
    end

    def view_template
      render DaisyUI::Select.new(*daisy_modifiers, **binding_attributes) do |el|
        render_prompt(el) if @prompt || @include_blank
        render_choices(el)
      end
    end

    private

    # The options are rendered inside DaisyUI::Select's block, so option/optgroup
    # resolve to the daisyui component's Phlex methods (yielded as `s`).
    def render_prompt(el)
      text = @prompt || (@include_blank.is_a?(String) ? @include_blank : "")
      el.option(value: "", selected: @selected.blank?) { text }
    end

    def render_choices(el)
      case @choices
      when Hash then render_hash_choices(el, @choices)
      else render_array_choices(el, Array(@choices))
      end
    end

    def render_array_choices(el, choices)
      choices.each do |choice|
        if choice.is_a?(Array)
          el.option(value: choice.last.to_s, selected: @selected.to_s == choice.last.to_s) { choice.first.to_s }
        else
          el.option(value: choice.to_s, selected: @selected.to_s == choice.to_s) { choice.to_s }
        end
      end
    end

    def render_hash_choices(el, choices)
      choices.each do |label, value|
        if value.is_a?(Array) || value.is_a?(Hash)
          el.optgroup(label:) do
            value.is_a?(Array) ? render_array_choices(el, value) : render_hash_choices(el, value)
          end
        else
          el.option(value: value.to_s, selected: @selected.to_s == value.to_s) { label.to_s }
        end
      end
    end
  end
end
