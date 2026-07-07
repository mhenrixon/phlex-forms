# frozen_string_literal: true

module RuboCop
  module Cop
    module PhlexForms
      # Flags Rails-style legacy form-builder methods (text_field, select, ...) in
      # favor of the phlex-forms API. The preferred primary path is the
      # Control-first `form.field(:name, ...)`; the PascalCase component methods
      # (form.Input/Select/Textarea/...) remain as escape hatches.
      #
      # @example
      #   # bad
      #   form.text_field(:name, :primary)
      #   form.select(:role, choices: roles)
      #
      #   # good (primary)
      #   form.field(:name, :primary)
      #   form.field(:role, as: :select, choices: roles)
      #
      #   # good (escape hatch)
      #   form.Input(:name, :primary)
      #   form.Select(:role, choices: roles)
      class LegacyFormMethod < Base
        INPUT_TYPE_METHODS = {
          text_field: :text,
          email_field: :email,
          password_field: :password,
          number_field: :number,
          date_field: :date,
          time_field: :time,
          datetime_field: :datetime,
          url_field: :url,
          tel_field: :tel,
          search_field: :search,
          range_field: :range,
          color_field: :color
        }.freeze

        OTHER_LEGACY_METHODS = {
          textarea: "Textarea",
          text_area: "Textarea",
          select: "Select",
          checkbox: "Checkbox",
          check_box: "Checkbox",
          radio_button: "Radio",
          toggle: "Toggle",
          file_field: "FileInput",
          hidden_field: "Hidden",
          form_control: "Control",
          label: "Label"
        }.freeze

        FORM_RECEIVERS = %i[form f af].freeze
        FORM_SUFFIX = /_form\z/

        def on_send(node)
          return unless form_receiver?(node)

          method_name = node.method_name
          return unless legacy_method?(method_name)

          add_offense(node.loc.selector, message: build_message(method_name, node))
        end

        private

        def form_receiver?(node)
          receiver = node.receiver
          return false unless receiver
          return false unless receiver.send_type? || receiver.lvar_type?

          receiver_name = receiver.send_type? ? receiver.method_name : receiver.children.first
          FORM_RECEIVERS.include?(receiver_name) || receiver_name.to_s.match?(FORM_SUFFIX)
        end

        def legacy_method?(method_name)
          INPUT_TYPE_METHODS.key?(method_name) || OTHER_LEGACY_METHODS.key?(method_name)
        end

        def build_message(method_name, node)
          replacement =
            if INPUT_TYPE_METHODS.key?(method_name)
              "form.Input(#{format_args_for_input(node, INPUT_TYPE_METHODS[method_name])})"
            else
              "form.#{OTHER_LEGACY_METHODS[method_name]}(#{format_args_passthrough(node)})"
            end

          "Use `form.field(...)` (or `#{replacement}`) instead of legacy " \
            "`#{node.receiver.source}.#{method_name}`."
        end

        def format_args_for_input(node, type_modifier)
          args = node.arguments
          [args.first&.source, ":#{type_modifier}", *args.drop(1).map(&:source)].compact.join(", ")
        end

        def format_args_passthrough(node)
          node.arguments.map(&:source).join(", ")
        end
      end
    end
  end
end
