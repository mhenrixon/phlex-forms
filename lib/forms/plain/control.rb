# frozen_string_literal: true

module Forms
  module Plain
    # The label + field + error/hint wrapper as a bare <div>, preserving
    # FormControl's ordering contract.
    class Control < Forms::FormControl
      def view_template
        div(**@options.except(:class), class: @options[:class]) do
          render Label.new(text: @label, for: @field_id, required: @required, id: @label_id) if @label

          yield if block_given?

          if @error
            render FieldError.new(message: @error)
          elsif @hint
            render FieldHint.new(text: @hint, id: @hint_id)
          end
        end
      end
    end
  end
end
