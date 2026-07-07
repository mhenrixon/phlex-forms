# frozen_string_literal: true

module Forms
  module Plain
    # Bare native <select>. Reuses Forms::Select's prompt/choice rendering
    # (arrays, pairs, hashes/optgroups, selected comparison). Also fills the
    # :choices_select theme role, so it swallows searchable: — there is no
    # choices.js in the plain theme.
    class Select < Forms::Select
      def initialize(*modifiers, searchable: false, **) # rubocop:disable Lint/UnusedMethodArgument
        super(*modifiers, **)
      end

      def view_template
        select(**unstyled_attributes) do
          render_prompt(self) if @prompt || @include_blank
          render_choices(self)
        end
      end
    end
  end
end
