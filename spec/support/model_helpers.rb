# frozen_string_literal: true

require "active_support/core_ext/string"

# A lightweight ActiveModel test double so component specs can exercise model
# binding, error hydration, human_attribute_name, and validation-based required
# inference without a database.
module ModelHelpers
  # Build an anonymous ActiveModel class with the given attributes and optional
  # validations, then instantiate it.
  #
  #   build_model(:user, email: "a@b.c",
  #     validations: -> { validates :email, presence: true })
  def build_model(name = :user, validations: nil, **attributes)
    model_name = name.to_s.camelize
    klass = Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      # ActiveModel::Naming needs a real class name; anonymous classes have none.
      define_singleton_method(:name) { model_name }

      attributes.each_key { |attr| attribute attr }
    end
    # Use class_exec (not class_eval) so an arity-0 lambda passed as `validations`
    # isn't rejected for receiving the implicit class argument class_eval passes.
    klass.class_exec(&validations) if validations
    klass.new(**attributes)
  end
end
