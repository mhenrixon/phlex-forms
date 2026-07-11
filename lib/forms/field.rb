# frozen_string_literal: true

# Per-field context: knows a field's name, its scope, the bound model, and the
# error set. Builds the concrete leaf components (input/textarea/select/...) with
# name/id/value/error wired in, and derives the label text and required flag.
#
# Not usually built directly — `Form#field_object(:name)` / the builder return one.
module Forms
  class Field
    # Data keys whose values are Stimulus token lists — merged by joining, not
    # replacing, so validation controllers and live triggers coexist.
    TOKEN_JOINED_DATA_KEYS = %i[controller action].freeze

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
    # Component classes resolve through the form's theme (see
    # PhlexForms::Theme), so the same field renders daisy or plain.

    def input(*modifiers, type: :text, **)
      theme[:input].new(*modifiers, type:, **field_attributes, **)
    end

    def textarea(*modifiers, **)
      theme[:textarea].new(*modifiers, **field_attributes, **)
    end
    alias text_area textarea

    def rich_textarea(*modifiers, **)
      theme[:rich_textarea].new(*modifiers, name: field_name, id: field_id, value: field_value, **)
    end
    alias rich_text_area rich_textarea

    def hidden(**)
      theme[:input].new(type: :hidden, **field_attributes, **)
    end

    # daisyui v5 "icon/text inside the field" wrapper. The block renders the
    # leading content (icon, prefix); the bare input is wired to this field.
    def wrapped_input(*modifiers, type: :text, **, &)
      theme[:wrapped_input].new(*modifiers, type:, **field_attributes.except(:error), error: invalid?, **, &)
    end

    def file(*modifiers, **)
      theme[:file].new(*modifiers, **field_attributes.except(:value), **)
    end

    def checkbox(*modifiers, **)
      theme[:checkbox].new(*modifiers, checked: field_value, **field_attributes.except(:value), **)
    end
    alias check_box checkbox

    def toggle(*modifiers, **)
      theme[:toggle].new(*modifiers, checked: field_value, **field_attributes.except(:value), **)
    end

    def radio(value, *modifiers, **options)
      # field_attributes carries value: field_value (the model's CURRENT value).
      # Drop it here so it can't clobber this radio's own positional value —
      # otherwise every radio in the group renders the model's value (issue #13).
      attrs = field_attributes.except(:value).merge(options)
      theme[:radio].new(
        *modifiers,
        value:,
        checked: field_value == value,
        **attrs.merge(id: "#{field_id}_#{value}")
      )
    end
    alias radio_button radio

    def select(choices = nil, **options)
      theme[:select].new(choices:, selected: field_value, **select_options(options))
    end

    # Enhanced select: choices.js-backed when searchable, native otherwise.
    def choices_select(choices = nil, *modifiers, **options)
      searchable = options.delete(:searchable) { false }
      opts = select_options(options)
      if searchable
        theme[:choices_select].new(*modifiers, choices:, selected: field_value, searchable: true, **opts)
      else
        theme[:select].new(*modifiers, choices:, selected: field_value, **opts)
      end
    end

    # A model-bound tag/chip input (phlex-reactive client-only primitives).
    # suggestions: an Array of tags or a Hash of tag => haystack (synonyms the
    # filter matches). Submits one comma-joined param under the field name.
    def tag_field(*modifiers, suggestions: [], **)
      theme[:tag_field].new(
        *modifiers,
        name: field_name, id: field_id, value: field_value,
        suggestions:, error: invalid?, **
      )
    end

    # A model-bound checkbox group over a collection. Shares one array-valued
    # field name (`scope[name][]`) and derives the checked set from the model's
    # current value, matched by each item's resolved value: (issue #9).
    #
    #   field.checkbox_group(Tag.all, value: :id, label: ->(t) { t.name })
    #
    # value: is a method name (Symbol) or a proc taking the item -> its submitted
    # value. The per-item visible text comes from item_label: (Symbol/Proc/String)
    # if given, else label:; when NEITHER is given each item is labelled by the
    # first of name/title/label/to_s it responds to (the same LABEL_METHODS chain
    # Inference uses for association choices) — so a plain
    # `f.field(:tags, as: :checkbox_group, label: "Tags")` shows readable item
    # text without an explicit accessor.
    #
    # item_label: exists so the `f.field` path can pass a visible group heading as
    # `label:` (consumed by the Control) AND still customize the per-item text
    # here — the two no longer collide. item_label: is consumed here; it never
    # leaks to the group div.
    def checkbox_group(collection, value: :id, label: nil, item_label: nil, **)
      text = item_label || label
      # The model's current value is already the raw values (e.g. record.tag_ids
      # => [1, 3]), so compare against them directly — don't re-resolve value:.
      selected = Array(field_value)
      opts = Array(collection).map do |item|
        item_value = resolve_item(item, value)
        {
          value: item_value,
          label: text ? resolve_item(item, text) : infer_item_label(item),
          checked: selected.include?(item_value),
          id: "#{field_id}_#{item_value}"
        }
      end
      theme[:checkbox_group].new(name: "#{field_name}[]", id: field_id, options: opts, error: invalid?, **)
    end

    def label(text = nil, *modifiers, **, &block)
      theme[:label].new(*modifiers, text: text || (block ? nil : field_label), for: field_id, **, &block)
    end

    def control(label: nil, hint: nil, required: false, **, &)
      theme[:control].new(label:, hint:, error: field_error_message, for: field_id, required:, **, &)
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

    def theme
      @theme ||= @form.respond_to?(:theme) ? @form.theme : PhlexForms::Theme.resolve(nil)
    end

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
        existing[key] = if TOKEN_JOINED_DATA_KEYS.include?(key)
          [existing[key], value].compact.reject { |s| s.to_s.empty? }.join(" ")
        else
          value
        end
      end
      existing
    end

    def conditional?(validator)
      validator.options.key?(:if) || validator.options.key?(:unless) || validator.options.key?(:on)
    end

    # value:/label:/item_label: for checkbox_group. A Proc is called with the
    # item; a String is literal text (the same for every item — no method
    # dispatch, so a stray string can't NoMethodError); anything else (a Symbol)
    # is sent to the item as a method name.
    def resolve_item(item, accessor)
      case accessor
      when Proc   then accessor.call(item)
      when String then accessor
      else item.public_send(accessor)
      end
    end

    # Default per-item label when no label:/item_label: was given: the first of
    # name/title/label/to_s the item responds to (mirrors PhlexForms::Inference's
    # LABEL_METHODS for association choices, so option text is picked the same way
    # across the gem).
    def infer_item_label(item)
      method = PhlexForms::Inference::LABEL_METHODS.find { |m| item.respond_to?(m) }
      item.public_send(method || :to_s)
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
