# frozen_string_literal: true

module RuboCop
  module Cop
    module PhlexForms
      # Enforces `Form()` (the phlex-forms kit helper) over `form_with` or a raw
      # `form()` element.
      #
      # @example
      #   # bad
      #   form_with(model: @user) { |f| }
      #   form(method: "post") { }
      #
      #   # good
      #   Form(model: @user) { |f| }
      class RawForm < Base
        extend AutoCorrector

        MSG_FORM_WITH = "Use `Form(model: @model)` instead of `form_with`."
        MSG_RAW_FORM = "Use `Form()` instead of raw `form()`."

        # @!method form_with_call?(node)
        def_node_matcher :form_with_call?, <<~PATTERN
          (send nil? :form_with ...)
        PATTERN

        # @!method raw_form_call?(node)
        def_node_matcher :raw_form_call?, <<~PATTERN
          (send nil? :form ...)
        PATTERN

        def on_send(node)
          if form_with_call?(node)
            add_offense(node.loc.selector, message: MSG_FORM_WITH) do |corrector|
              corrector.replace(node.loc.selector, "Form")
            end
          elsif raw_form_call?(node)
            # Skip bare `form` with no args and no block — it's a variable/method
            # reference, not a Phlex form element (e.g. `form.label(...)`,
            # `IconField(form:)`).
            return if node.arguments.empty? && !node.block_node

            add_offense(node.loc.selector, message: MSG_RAW_FORM) do |corrector|
              corrector.replace(node.loc.selector, "Form")
            end
          end
        end
      end
    end
  end
end
