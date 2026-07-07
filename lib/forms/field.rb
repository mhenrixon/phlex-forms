# frozen_string_literal: true

# Per-field context: knows a field's name, its scope, the bound model, and the
# error set. Builds the concrete leaf components (input/textarea/select/...) with
# name/id/value/error wired in, and derives the label text and required flag.
#
# Not usually built directly — `Form#field_object(:name)` / the builder return one.
module Forms
  class Field
    attr_reader :name, :model, :scope, :errors

    # error_name: where errors live when it differs from the input's name — an
    # inferred belongs_to select is named :country_id but Rails attaches its
    # errors to :country.
    def initialize(name:, model:, scope:, errors:, form:, error_name: nil)
      @name = name
      @error_name = error_name || name
      @model = model
      @scope = scope
      @errors = errors
      @form = form
    end

    # --- leaf component builders (return component instances to render) ---

    def input(*modifiers, type: :text, **)
      Forms::Input.new(*modifiers, type:, **field_attributes, **)
    end

    def textarea(*modifiers, **)
      Forms::Textarea.new(*modifiers, **field_attributes, **)
    end
    alias text_area textarea

    def rich_textarea(*modifiers, **)
      Forms::RichTextarea.new(*modifiers, name: field_name, id: field_id, value: field_value, **)
    end
    alias rich_text_area rich_textarea

    def hidden(**)
      Forms::Input.new(type: :hidden, **field_attributes, **)
    end

    # daisyui v5 "icon/text inside the field" wrapper. The block renders the
    # leading content (icon, prefix); the bare input is wired to this field.
    def wrapped_input(*modifiers, type: :text, **, &)
      Forms::WrappedInput.new(*modifiers, type:, **field_attributes.except(:error), error: invalid?, **, &)
    end

    def file(*modifiers, **)
      Forms::FileInput.new(*modifiers, **field_attributes.except(:value), **)
    end

    def checkbox(*modifiers, **)
      Forms::Checkbox.new(*modifiers, checked: field_value, **field_attributes.except(:value), **)
    end
    alias check_box checkbox

    def toggle(*modifiers, **)
      Forms::Toggle.new(*modifiers, checked: field_value, **field_attributes.except(:value), **)
    end

    def radio(value, *modifiers, **options)
      Forms::Radio.new(
        *modifiers,
        value:,
        checked: field_value == value,
        **field_attributes.merge(options).merge(id: "#{field_id}_#{value}")
      )
    end
    alias radio_button radio

    def select(choices = nil, **options)
      Forms::Select.new(choices:, selected: field_value, **select_options(options))
    end

    # Enhanced select: choices.js-backed when searchable, native otherwise.
    def choices_select(choices = nil, *modifiers, **options)
      searchable = options.delete(:searchable) { false }
      opts = select_options(options)
      if searchable
        Forms::ChoicesSelect.new(*modifiers, choices:, selected: field_value, searchable: true, **opts)
      else
        Forms::Select.new(*modifiers, choices:, selected: field_value, **opts)
      end
    end

    def label(text = nil, *modifiers, **, &block)
      Forms::Label.new(*modifiers, text: text || (block ? nil : field_label), for: field_id, **, &block)
    end

    def control(label: nil, hint: nil, required: false, **, &)
      Forms::FormControl.new(label:, hint:, error: field_error_message, for: field_id, required:, **, &)
    end

    # --- derived metadata ---

    # Humanized label text: the model's human_attribute_name when available.
    def field_label
      if @model.respond_to?(:class) && @model.class.respond_to?(:human_attribute_name)
        @model.class.human_attribute_name(@name)
      else
        @name.to_s.tr("_", " ").capitalize
      end
    end

    # Inferred from the model's presence validators (ActiveModel). False when the
    # model doesn't expose validators.
    def required?
      return false unless @model.respond_to?(:class) && @model.class.respond_to?(:validators_on)

      @model.class.validators_on(@name).any? do |v|
        v.is_a?(ActiveModel::Validations::PresenceValidator) && !conditional?(v)
      end
    rescue StandardError
      false
    end

    def invalid?
      return false unless @errors

      @errors.include?(@name) || @errors.include?(@error_name)
    end

    def field_name
      @scope ? "#{@scope}[#{@name}]" : @name.to_s
    end

    def field_id
      if @scope
        "#{@scope.tr('[', '_').delete(']')}_#{@name}"
      else
        @name.to_s
      end
    end

    # Ransack-safe getter: dispatches through method_missing consumers (e.g.
    # Ransack::Search predicate getters) but only swallows the direct dispatch miss.
    def field_value
      return nil unless @model

      @model.public_send(@name)
    rescue NoMethodError => e
      raise unless e.receiver.equal?(@model) && e.name == @name

      nil
    end

    # --- client-side validation wiring (pairs with Forms::Validations) ---

    # Merge a per-call `validate:` override into the field's option hash. Strips
    # `:validate` and, when rules apply, merges the Stimulus data into `data:`.
    # Falls back to the form-level introspector when `:validate` is absent.
    #
    #   validate: false           → opt this field out
    #   validate: true            → the form-level introspector
    #   validate: { length: {…} } → explicit inline rules
    def apply_validations(options)
      return consume_validate(options) if options.key?(:validate)

      data = form_introspector.data_attributes_for(@name)
      return options if data.empty?

      options.merge(data: merge_data(options[:data], data))
    end

    private

    def consume_validate(options)
      return options unless options.key?(:validate)

      override = options.delete(:validate)
      data = validation_data_for(override)
      return options if data.empty?

      options.merge(data: merge_data(options[:data], data))
    end

    def validation_data_for(override)
      case override
      when true then form_introspector.data_attributes_for(@name)
      when Hash then Forms::Validations::ManualRules.new(override).data_attributes
      else {} # false / nil / anything else → no client-side validation
      end
    end

    def form_introspector
      if @form.respond_to?(:validations_introspector)
        @form.validations_introspector
      else
        Forms::Validations::Introspector::Null.new
      end
    end

    def merge_data(existing, additions)
      existing = (existing || {}).dup
      additions.each do |key, value|
        if key == :controller
          existing[:controller] = [existing[:controller], value].compact.reject { |s| s.to_s.empty? }.join(" ")
        else
          existing[key] = value
        end
      end
      existing
    end

    def conditional?(validator)
      validator.options.key?(:if) || validator.options.key?(:unless) || validator.options.key?(:on)
    end

    def field_attributes
      { name: field_name, id: field_id, value: field_value, error: invalid? }
    end

    def field_error_message
      return nil unless invalid?

      @errors.full_messages_for(@name).first || @errors.full_messages_for(@error_name).first
    end

    def select_options(options)
      include_blank = options.delete(:include_blank)
      prompt = options.delete(:prompt)
      opts = field_attributes.merge(options)
      opts[:include_blank] = include_blank unless include_blank.nil?
      opts[:prompt] = prompt unless prompt.nil?
      opts
    end
  end
end
