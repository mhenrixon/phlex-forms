# frozen_string_literal: true

module Forms
  module Plain
    # The rootless tag field under the plain theme: the wire contract of
    # Forms::RootlessTagField with the bare-styling seams of Forms::Plain::TagField.
    # Multiple-inheritance-free: subclass the rootless variant and re-apply the
    # plain seam overrides.
    class RootlessTagField < Forms::RootlessTagField
      private

      def root_classes = "tag-field"
      def list_classes = nil
      def menu_classes = nil
      def option_classes = nil
      def chip_classes = nil
      def remove_classes = nil
      def input_classes = @attributes[:class]
    end
  end
end
