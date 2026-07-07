# frozen_string_literal: true

module Forms
  module Plain
    # The icon/text-inside-the-field pattern without daisyui: a bare <label>
    # wrapping the leading block, the input, and any trailing content.
    class WrappedInput < Forms::WrappedInput
      def view_template(&leading)
        label do
          leading&.call
          input(**plain_input_attributes)
          render_trailing
        end
      end

      private

      def plain_input_attributes
        attrs = {
          type: @type,
          name: @name,
          id: @id,
          value: @value.to_s,
          placeholder: @placeholder,
          **@attributes.except(:error, :value, :class)
        }
        attrs[:disabled] = true if @disabled
        attrs[:required] = true if @required
        attrs[:"aria-invalid"] = true if @error
        attrs.compact
      end
    end
  end
end
