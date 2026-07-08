# frozen_string_literal: true

module Forms
  module Plain
    # Bare tag/chip input. Inherits the ENTIRE reactive wire contract from
    # Forms::TagField (the client behavior must still work under the plain theme)
    # and overrides only the styling seams to ship zero daisyUI classes. The
    # invalid state rides aria-invalid on the query input, never a color class.
    #
    # Like its parent, this file autoloads only when Phlex::Reactive is present
    # (it inherits from a ClientBindings-including class).
    class TagField < Forms::TagField
      private

      def root_classes = "tag-field"
      def list_classes = nil
      def menu_classes = nil
      def chip_classes = nil
      def remove_classes = nil
      def input_classes = @attributes[:class]
    end
  end
end
