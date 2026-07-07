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

    def field_object(name)
      Forms::Field.new(name:, model: @model, scope: @scope, errors: @errors, form: @parent_form)
    end

    # Nested fields_for (single association or has_many collection).
    def fields_for(association_name, model = nil, &)
      return unless block_given?

      associated = model || (@model.public_send(association_name) if @model.respond_to?(association_name))
      base_scope = "#{@scope}[#{association_name}_attributes]"

      if associated.respond_to?(:each_with_index)
        associated.each_with_index do |item, index|
          yield build_nested("#{base_scope}[#{index}]", item)
        end
      else
        yield build_nested(base_scope, associated)
      end
    end

    def field_name(name) = "#{@scope}[#{name}]"
    def field_id(name)   = "#{@scope.tr('[', '_').delete(']')}_#{name}"

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
