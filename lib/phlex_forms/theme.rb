# frozen_string_literal: true

module PhlexForms
  # A theme maps component roles (:input, :select, :control, ...) to component
  # classes. The binding contract — the leaf initializer signatures
  # (*modifiers, name:, id:, value:, error:, required:, ...) — is the stable
  # interface, so the same form class renders under any theme.
  #
  # Built-ins:
  #   Theme.daisy — the DaisyUI-delegating Forms::* leaves (default when the
  #                 daisyui gem is loaded)
  #   Theme.plain — bare semantic HTML (Forms::Plain::*): variants accepted and
  #                 ignored, zero styling classes, aria/data hooks only
  #
  # Select per form (`Form(model:, theme: :plain)`), per class
  # (`form_options theme: :plain`), or globally
  # (`PhlexForms.configure { |c| c.theme = :plain }`). Override single roles:
  #
  #   PhlexForms::Theme.resolve(:plain).with(input: MyInput)
  class Theme
    def initialize(components)
      @components = components.freeze
    end

    def [](role)
      @components.fetch(role) do
        raise KeyError, "unknown theme role #{role.inspect} (roles: #{@components.keys.join(', ')})"
      end
    end

    def with(**overrides)
      self.class.new(@components.merge(overrides))
    end

    class << self
      def resolve(value)
        value = PhlexForms.config.theme if value.nil?
        case value
        when Theme then value
        when :daisy then daisy
        when :plain then plain
        else
          raise ArgumentError, "unknown theme #{value.inspect} (use :daisy, :plain, or a PhlexForms::Theme)"
        end
      end

      def daisy
        unless defined?(DaisyUI)
          raise PhlexForms::FeatureUnavailable,
            "the daisy theme requires the daisyui gem. Add `gem \"daisyui\"` to your " \
            "Gemfile, or use the plain theme."
        end

        @daisy ||= new({
          input: Forms::Input, select: Forms::Select, choices_select: Forms::ChoicesSelect,
          textarea: Forms::Textarea, rich_textarea: Forms::RichTextarea,
          checkbox: Forms::Checkbox, toggle: Forms::Toggle, radio: Forms::Radio,
          file: Forms::FileInput, wrapped_input: Forms::WrappedInput,
          control: Forms::FormControl, label: Forms::Label,
          field_error: Forms::FieldError, field_hint: Forms::FieldHint,
          submit: Forms::Submit, row: Forms::Row, group: Forms::Group,
          # tag_field is phlex-reactive-gated (ClientBindings); only registered
          # when the soft dep is present, else :tag_field raises a clear KeyError.
          **reactive_roles(Forms::TagField)
        })
      end

      # choices_select degrades to the native plain select (no choices.js) and
      # rich_textarea to a plain textarea; toggle renders as a checkbox.
      def plain
        @plain ||= new({
          input: Forms::Plain::Input, select: Forms::Plain::Select, choices_select: Forms::Plain::Select,
          textarea: Forms::Plain::Textarea, rich_textarea: Forms::Plain::Textarea,
          checkbox: Forms::Plain::Checkbox, toggle: Forms::Plain::Checkbox, radio: Forms::Plain::Radio,
          file: Forms::Plain::FileInput, wrapped_input: Forms::Plain::WrappedInput,
          control: Forms::Plain::Control, label: Forms::Plain::Label,
          field_error: Forms::Plain::FieldError, field_hint: Forms::Plain::FieldHint,
          submit: Forms::Plain::Submit, row: Forms::Plain::Row, group: Forms::Plain::Group,
          **reactive_roles(Forms::Plain::TagField)
        })
      end

      private

      # phlex-reactive-gated roles: mapped only when the soft dep is present. When
      # absent, the leaf classes aren't autoloaded, so :tag_field is simply not a
      # role (fetching it raises the theme's own KeyError with the role list).
      def reactive_roles(tag_field_class)
        return {} unless defined?(Phlex::Reactive)

        { tag_field: tag_field_class }
      end
    end
  end
end
