# frozen_string_literal: true

module Forms
  # Declarative form classes: subclass, declare the fields in #fields, render.
  # Inside #fields, `self` IS the form — the whole builder surface (field, row,
  # group, Input, submit, fields_for, ...) is available as bare calls.
  #
  #   class UserForm < Forms::Base
  #     form_options :spaced
  #
  #     def fields
  #       field :email
  #       row { field :first_name; field :last_name }
  #       submit :primary
  #     end
  #   end
  #
  #   render UserForm.new(model: @user)
  #
  # A render-time block appends after the declared fields:
  #
  #   render UserForm.new(model: @user) { |f| f.Hidden(:token) }
  class Base < Form
    class << self
      # Class-level defaults, inherited and merged down the subclass chain
      # (instance args beat class defaults; subclass defaults beat parents'):
      #
      #   form_options :spaced, url: "/signup", validate: true
      def form_options(*modifiers, **defaults)
        @form_modifiers = modifiers
        @form_defaults = defaults
      end

      def form_modifiers
        inherited = superclass.respond_to?(:form_modifiers) ? superclass.form_modifiers : []
        (inherited + (@form_modifiers || [])).uniq
      end

      def form_defaults
        inherited = superclass.respond_to?(:form_defaults) ? superclass.form_defaults : {}
        inherited.merge(@form_defaults || {})
      end
    end

    def initialize(*modifiers, **options)
      super(*(self.class.form_modifiers + modifiers).uniq, **self.class.form_defaults.merge(options))
    end

    # Renders Form's chrome (action/method/CSRF/enctype), then the declared
    # fields. `yield`/`block_given?` inside the inner block bind to
    # view_template's own block — the optional render-time block.
    def view_template
      super do
        fields
        yield self if block_given?
      end
    end

    # The hook name `fields` is verified free against Phlex::HTML (phlex 2.4.x)
    # and this gem (Form defines fields_for/field_object, never fields).
    def fields
      raise NotImplementedError, "#{self.class} must define #fields"
    end
  end
end
