# frozen_string_literal: true

module Forms
  module Plain
    # Bare checkbox group. Inherits the whole binding contract from
    # Forms::CheckboxGroup (the shared array name, the empty-array hidden field,
    # the per-item checked state) and overrides only the rendering seams to ship
    # zero daisyUI classes. The invalid state rides aria-invalid on the group,
    # never a color class.
    class CheckboxGroup < Forms::CheckboxGroup
      private

      # Bare <input type=checkbox>, no DaisyUI delegation, no styling classes.
      def render_checkbox(option)
        input(
          type: "checkbox", name: @name, id: option[:id],
          value: option[:value], class: @attributes[:class],
          checked: option[:checked] || nil
        )
      end

      def group_classes = @attributes[:class]
      def item_classes = nil
      def item_label_classes = nil
    end
  end
end
