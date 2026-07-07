# frozen_string_literal: true

module Forms
  # A time-zone `<select>` populated by Rails' time_zone_options_for_select,
  # delegating the styling to DaisyUI::Select and wiring the `tz` Stimulus
  # controller (which auto-selects the browser's zone when none is set).
  #
  # Requires phlex-rails' TimeZoneOptionsForSelect helper (a Rails host); outside
  # Rails, pass explicit `choices` to a plain Forms::Select instead.
  class TimeZoneSelect < Phlex::HTML
    include PhlexForms::DelegatedField

    include Phlex::Rails::Helpers::TimeZoneOptionsForSelect if defined?(Phlex::Rails::Helpers::TimeZoneOptionsForSelect)

    def initialize(*modifiers, name: nil, id: nil, selected: nil, priority_zones: nil,
                   model: ActiveSupport::TimeZone, placeholder: nil, include_blank: false,
                   error: false, disabled: false, required: false, full_width: true, **attributes)
      @modifiers = normalize_modifiers(modifiers)
      @name = name
      @id = id
      @selected = selected
      @priority_zones = priority_zones
      @zone_model = model
      @placeholder = placeholder
      @include_blank = include_blank
      @error = error
      @disabled = disabled
      @required = required
      @full_width = full_width
      @attributes = attributes
      super()
    end

    def view_template
      render DaisyUI::Select.new(*daisy_modifiers, **select_attributes) do |el|
        render_placeholder(el) if @placeholder || @include_blank
        el.raw(el.safe(time_zone_options_for_select(@selected, @priority_zones, @zone_model)))
      end
    end

    private

    def select_attributes
      data = { controller: "tz" }.merge(@attributes[:data] || {})
      binding_attributes(data:).except(:value)
    end

    def render_placeholder(el)
      el.option(value: "", disabled: true, selected: @selected.blank?) { @placeholder.to_s }
    end
  end
end
