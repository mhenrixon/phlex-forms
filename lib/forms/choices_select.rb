# frozen_string_literal: true

# A searchable/multi-select `<select>` enhanced by the choices.js Stimulus
# controller (shipped with the gem). Renders a normal `<select>` server-side; the
# `choices` controller upgrades it on connect. Size/color are passed as data
# values and applied to the choices.js wrapper by the controller.
module Forms
  class ChoicesSelect < Forms::Base
    def initialize(*, name: nil, id: nil, choices: [], selected: nil, multiple: false,
                   searchable: false, remove_item_button: nil, placeholder: nil,
                   include_blank: false, prompt: nil, error: false, disabled: false, required: false, **)
      super(*, **)
      @name = name
      @id = id
      @choices = choices
      @selected = selected
      @multiple = multiple
      @searchable = searchable
      @remove_item_button = remove_item_button.nil? ? multiple : remove_item_button
      @placeholder = placeholder
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
      a = {
        name: select_name,
        id: @id,
        class: PhlexForms::ClassMerge.merge("choices-select w-full", options[:class]),
        data: stimulus_data,
        **options.except(:class, :value, :data)
      }
      a[:multiple] = true if @multiple
      a[:disabled] = true if @disabled
      a[:required] = true if @required
      a.compact
    end

    def select_name
      return nil unless @name

      @multiple ? "#{@name}[]" : @name
    end

    def stimulus_data
      base = options[:data] || {}
      {
        controller: [base[:controller], "choices"].compact.join(" "),
        choices_searchable_value: @searchable,
        choices_remove_item_button_value: @remove_item_button,
        choices_placeholder_value: @placeholder.to_s,
        choices_size_value: size_value,
        choices_color_value: color_value,
        **base.except(:controller)
      }
    end

    def size_value
      %i[xs sm md lg xl].find { |s| modifiers.include?(s) }.to_s
    end

    def color_value
      (%i[primary secondary accent neutral info success warning error]
        .find { |c| modifiers.include?(c) } || :primary).to_s
    end

    def render_prompt
      text = @prompt || (@include_blank.is_a?(String) ? @include_blank : "")
      option(value: "", selected: blank_selected?) { text }
    end

    def blank_selected?
      @multiple ? Array(@selected).empty? : @selected.blank?
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
          render_option(choice[1], choice[0])
        else
          render_option(choice, choice)
        end
      end
    end

    def render_hash_choices(choices)
      choices.each do |label, value|
        if value.is_a?(Array) || value.is_a?(Hash)
          optgroup(label:) { value.is_a?(Array) ? render_array_choices(value) : render_hash_choices(value) }
        else
          render_option(value, label)
        end
      end
    end

    def render_option(value, label)
      option(value: value.to_s, selected: selected?(value) || nil) { label.to_s }
    end

    def selected?(value)
      if @multiple
        Array(@selected).map(&:to_s).include?(value.to_s)
      else
        @selected.to_s == value.to_s
      end
    end

    register_modifiers(
      primary: nil, secondary: nil, accent: nil, neutral: nil,
      info: nil, success: nil, warning: nil, error: nil,
      xs: nil, sm: nil, md: nil, lg: nil, xl: nil
    )
  end
end
