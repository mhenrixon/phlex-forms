# frozen_string_literal: true

# A native daisyui-styled `<select>`. daisyui v5 puts the `select` class directly
# on the `<select>` element (no wrapper label needed).
module Forms
  class Select < Forms::Base
    def initialize(*, name: nil, id: nil, choices: [], selected: nil,
                   include_blank: false, prompt: nil, error: false, disabled: false, required: false, **)
      super(*, **)
      @name = name
      @id = id
      @choices = choices
      @selected = selected
      @include_blank = include_blank
      @prompt = prompt
      @error = error
      @disabled = disabled
      @required = required
    end

    def view_template
      select(**attrs) do
        render_prompt if @prompt || @include_blank
        render_choices
      end
    end

    private

    def attrs
      a = { name: @name, id: @id, class: final_classes, **options.except(:class, :value, :error) }
      a[:disabled] = true if @disabled
      a[:required] = true if @required
      a.compact
    end

    def final_classes
      error_class = "select-error" if @error && modifiers.exclude?(:error)
      merge_classes("select w-full", error_class, *registered_modifier_classes, options[:class])
    end

    def render_prompt
      text = @prompt || (@include_blank.is_a?(String) ? @include_blank : "")
      option(value: "", selected: @selected.blank?) { text }
    end

    def render_choices
      case @choices
      when Hash then render_hash_choices(@choices)
      else render_array_choices(Array(@choices))
      end
    end

    def render_array_choices(choices)
      choices.each do |choice|
        if choice.is_a?(Array)
          option(value: choice.last.to_s, selected: @selected.to_s == choice.last.to_s) { choice.first.to_s }
        else
          option(value: choice.to_s, selected: @selected.to_s == choice.to_s) { choice.to_s }
        end
      end
    end

    def render_hash_choices(choices)
      choices.each do |label, value|
        if value.is_a?(Array) || value.is_a?(Hash)
          optgroup(label:) { value.is_a?(Array) ? render_array_choices(value) : render_hash_choices(value) }
        else
          option(value: value.to_s, selected: @selected.to_s == value.to_s) { label.to_s }
        end
      end
    end

    register_modifiers(
      primary: "select-primary",
      secondary: "select-secondary",
      accent: "select-accent",
      info: "select-info",
      success: "select-success",
      warning: "select-warning",
      error: "select-error",
      neutral: "select-neutral",
      ghost: "select-ghost",
      xs: "select-xs",
      sm: "select-sm",
      md: "select-md",
      lg: "select-lg",
      xl: "select-xl"
    )
  end
end
