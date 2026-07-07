# frozen_string_literal: true

module PhlexForms
  # Model-driven input inference for Builder#field. Pure introspection: every
  # model touch sits behind respond_to? guards and a StandardError rescue (the
  # same posture as Forms::Field#required?), so plain objects, Structs, and
  # POROs fall through to the attribute-name map exactly as before. No
  # ActiveRecord dependency.
  #
  # Precedence (first hit wins):
  #   1. explicit as:                      (caller always wins)
  #   2. positional type modifier          (f.field :price, :number)
  #   3. explicit choices:                 -> :select
  #   4. model structure: rich text, attachment, enum, belongs_to
  #   5. non-string column type            (COLUMN_TYPE_MAP)
  #   6. attribute-name map                (Builder::INPUT_TYPE_INFERENCE)
  #   7. :text
  #
  # Validator-derived attributes (maxlength/min/max) merge orthogonally and
  # always lose to caller-passed options. Steps 4-5 and the validator attrs are
  # gated by `PhlexForms.config.infer_from_model` (default on).
  module Inference
    Result = Data.define(:as, :name, :label, :choices, :attributes, :multiple, :required) do
      def self.blank(as:, name:)
        new(as:, name:, label: nil, choices: nil, attributes: {}, multiple: false, required: nil)
      end
    end

    # Option-text methods tried in order when building association choices.
    LABEL_METHODS = %i[name title label to_s].freeze

    # Column type -> control kind, for non-string columns only (the name map
    # disambiguates strings; the column type is ground truth for other shapes).
    COLUMN_TYPE_MAP = {
      boolean: :toggle,
      text: :textarea,
      date: :date,
      datetime: :datetime,
      timestamptz: :datetime,
      time: :time,
      integer: :number,
      decimal: :number,
      float: :number
    }.freeze

    # Kinds that accept a maxlength attribute.
    TEXT_LIKE = %i[text email password tel url search textarea].freeze

    module_function

    def resolve(model:, name:, as: nil, modifiers: [], choices: nil)
      result = base_result(model:, name:, as:, modifiers:, choices:)
      return result unless infer_from_model?

      validator_attrs = validator_attributes(model, result.name, result.as)
      return result if validator_attrs.empty?

      result.with(attributes: validator_attrs.merge(result.attributes))
    end

    def base_result(model:, name:, as:, modifiers:, choices:)
      return Result.blank(as:, name:) if as

      if (explicit = modifiers.find { |m| Builder::INPUT_TYPE_MODIFIERS.include?(m) })
        return Result.blank(as: explicit, name:)
      end
      return Result.blank(as: :select, name:) if choices
      return name_map_result(name) unless infer_from_model?

      structural(model, name) || from_column(model, name) || name_map_result(name)
    end

    def infer_from_model?
      PhlexForms.config.infer_from_model
    end

    def name_map_result(name)
      Result.blank(as: Builder::INPUT_TYPE_INFERENCE[name.to_sym] || :text, name:)
    end

    def structural(model, name)
      return nil unless model

      rich_text(model, name) || attachment(model, name) ||
        enum(model, name) || association(model, name)
    rescue StandardError
      nil
    end

    # ActionText defines a has_one :rich_text_<name> association.
    def rich_text(model, name)
      return nil unless reflect(model, :"rich_text_#{name}")

      Result.blank(as: :rich_textarea, name:)
    end

    def attachment(model, name)
      klass = model.class
      return nil unless klass.respond_to?(:reflect_on_attachment)

      reflection = klass.reflect_on_attachment(name)
      return nil unless reflection

      Result.blank(as: :file, name:).with(multiple: reflection.macro == :has_many_attached)
    end

    def enum(model, name)
      klass = model.class
      return nil unless klass.respond_to?(:defined_enums) && klass.defined_enums.key?(name.to_s)

      pairs = klass.defined_enums[name.to_s].keys.map { |key| [key.humanize, key] }
      Result.blank(as: :select, name:).with(choices: pairs)
    end

    # A non-polymorphic belongs_to, matched by the association name (:country)
    # or its foreign key (:country_id). The field name is rewritten to the
    # foreign key; the label and required flag come from the association.
    def association(model, name)
      assoc_name = name.to_s.delete_suffix("_id").to_sym
      reflection = reflect(model, name) || reflect(model, assoc_name)
      return nil unless reflection && reflection.macro == :belongs_to && !reflection.polymorphic?

      Result.blank(as: :select, name: reflection.foreign_key.to_sym).with(
        label: association_label(model, reflection),
        choices: -> { association_choices(reflection.klass) }, # lazy: only called without a choices: override
        required: presence_validated?(model, reflection.name)
      )
    end

    def from_column(model, name)
      type = column_type(model, name)
      kind = COLUMN_TYPE_MAP[type&.type]
      return nil unless kind

      attrs = {}
      if kind == :number && (step = step_for(type))
        attrs[:step] = step
      end
      Result.blank(as: kind, name:).with(attributes: attrs)
    rescue StandardError
      nil
    end

    def column_type(model, name)
      return nil unless model

      klass = model.class
      if klass.respond_to?(:type_for_attribute)
        klass.type_for_attribute(name.to_s)
      elsif klass.respond_to?(:attribute_types)
        klass.attribute_types[name.to_s]
      end
    end

    def step_for(type)
      case type.type
      when :integer then 1
      when :decimal, :float
        scale = type.respond_to?(:scale) ? type.scale : nil
        scale ? (10**-scale).to_f : "any"
      end
    end

    def association_label(model, reflection)
      klass = model.class
      return nil unless klass.respond_to?(:human_attribute_name)

      klass.human_attribute_name(reflection.name)
    end

    def association_choices(klass)
      label_method = nil
      klass.all.map do |record|
        label_method ||= LABEL_METHODS.find { |m| record.respond_to?(m) }
        [record.public_send(label_method), record.id]
      end
    end

    def presence_validated?(model, attr)
      klass = model.class
      return false unless klass.respond_to?(:validators_on)

      klass.validators_on(attr).any? do |v|
        v.is_a?(ActiveModel::Validations::PresenceValidator) && !conditional?(v)
      end
    end

    # Length maximum -> maxlength (text-like kinds); numericality bounds ->
    # min/max (number kind only; exclusive bounds map +/-1 only for
    # only_integer, otherwise skipped).
    def validator_attributes(model, name, kind)
      return {} unless model.respond_to?(:class) && model.class.respond_to?(:validators_on)

      attrs = {}
      model.class.validators_on(name).each do |validator|
        next if conditional?(validator)

        case validator
        when ActiveModel::Validations::LengthValidator
          max = validator.options[:maximum]
          attrs[:maxlength] = max if max && TEXT_LIKE.include?(kind)
        when ActiveModel::Validations::NumericalityValidator
          attrs.merge!(numericality_attributes(validator.options)) if kind == :number
        end
      end
      attrs
    rescue StandardError
      {}
    end

    def numericality_attributes(options)
      attrs = {}
      integer = options[:only_integer]
      if (min = options[:greater_than_or_equal_to])
        attrs[:min] = min
      elsif integer && (gt = options[:greater_than])
        attrs[:min] = gt + 1
      end
      if (max = options[:less_than_or_equal_to])
        attrs[:max] = max
      elsif integer && (lt = options[:less_than])
        attrs[:max] = lt - 1
      end
      attrs
    end

    def reflect(model, name)
      klass = model.class
      return nil unless klass.respond_to?(:reflect_on_association)

      klass.reflect_on_association(name)
    end

    def conditional?(validator)
      validator.options.key?(:if) || validator.options.key?(:unless) || validator.options.key?(:on)
    end
  end
end
