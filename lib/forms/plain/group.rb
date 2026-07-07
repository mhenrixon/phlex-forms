# frozen_string_literal: true

module Forms
  module Plain
    # Semantic <fieldset>/<legend> without daisyui classes.
    class Group < Forms::Group
      def view_template
        fieldset(**@options.except(:class), class: @options[:class]) do
          legend { @legend } if @legend
          yield if block_given?
        end
      end
    end
  end
end
