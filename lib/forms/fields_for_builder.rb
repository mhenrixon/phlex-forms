# frozen_string_literal: true

module Forms
  # Yielded inside Form#fields_for for nested attributes. Reuses the shared
  # Builder API (f.field, f.Input, ...) against a nested scope, rendering through
  # the parent form.
  class FieldsForBuilder
    include PhlexForms::Builder

    attr_reader :model, :scope, :errors, :parent_form

    def initialize(model:, scope:, errors:, parent_form:)
      @model = model
      @scope = scope
      @errors = errors
      @parent_form = parent_form
    end

    # The Builder mixin renders through `render`; delegate to the parent form.
    def render(...)
      @parent_form.render(...)
    end

    def field_object(name, error_name: nil)
      Forms::Field.new(name:, model: @model, scope: @scope, errors: @errors, form: @parent_form, error_name:)
    end

    def default_field_variants
      @parent_form.default_field_variants
    end

    def theme
      @parent_form.theme
    end

    # Nested fields_for (single association or has_many collection).
    # nested_attributes: false nests under the raw name (JSONB/hash columns).
    def fields_for(association_name, model = nil, nested_attributes: true, &)
      return unless block_given?

      associated = model || (@model.public_send(association_name) if @model.respond_to?(association_name))
      attributes_key = nested_attributes ? "#{association_name}_attributes" : association_name.to_s
      base_scope = "#{@scope}[#{attributes_key}]"

      if associated.respond_to?(:each_with_index)
        associated.each_with_index do |item, index|
          yield build_nested("#{base_scope}[#{index}]", item)
        end
      else
        yield build_nested(base_scope, associated)
      end
    end

    def field_name(name)  = "#{@scope}[#{name}]"
    def field_id(name)    = "#{@scope.tr('[', '_').delete(']')}_#{name}"
    def field_value(name) = field_object(name).field_value

    private

    def build_nested(scope, item)
      self.class.new(
        model: item,
        scope:,
        errors: (item.errors if item.respond_to?(:errors)),
        parent_form: @parent_form
      )
    end
  end
end
