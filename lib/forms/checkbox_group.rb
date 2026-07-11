# frozen_string_literal: true

module Forms
  # A batched checkbox group for an array-valued field (the tag/facet-picker
  # shape). Renders a set of checkboxes sharing ONE array-valued field name
  # (`user[tag_ids][]`), with a leading empty-array hidden field so an empty
  # selection still submits, and derives each box's checked state from the
  # resolved value: of its item against the model's current set.
  #
  #   f.checkbox_group(:tag_ids, Tag.all, value: :id,
  #     item_label: ->(t) { t.name.presence || t.slug }, variant: :pill, size: :sm)
  #
  # The item value/text accessors (value:/label:/item_label:) live on the BUILDER
  # (Forms::Field#checkbox_group), which pre-resolves each item to
  # { value:, label:, checked:, id: } before this leaf renders. This leaf is
  # presentation-only — it receives the resolved options: array, never the raw
  # accessors.
  # variant: :stack (default) | :inline | :pill — layout only, zero JS
  # size:    daisyUI checkbox size modifier (:xs :sm :md :lg :xl)
  #
  # Accessible name (issue #17): `role="group"` needs one so a screen reader
  # announces the group when focus enters a checkbox. The leaf does NOT invent
  # its own naming API — extra attributes pass straight through to the group
  # `div`, so the caller names it with plain HTML/ARIA:
  #
  #   f.checkbox_group(:tag_ids, Tag.all, value: :id, aria: { label: "Tags" })
  #   f.checkbox_group(:tag_ids, Tag.all, value: :id, aria: { labelledby: "hdr" })
  #
  # Through `f.field`, the builder points the group at the Control's own visible
  # <label>/hint via `aria: { labelledby:, describedby: }` (so the accessible
  # name matches what sighted users see) — same passthrough, no special API.
  #
  # The checked set is passed in pre-resolved by the builder (Field#checkbox_group
  # matches the model's current value by each item's resolved value:), so the
  # component itself stays presentation-only. Each checkbox's markup is delegated
  # to DaisyUI::Checkbox so its size class is a literal, scanner-visible token.
  class CheckboxGroup < Phlex::HTML
    # variant -> the container class. The pill variant uses Tailwind's
    # `has-[:checked]:` to style the active label with no JS.
    VARIANT_CLASSES = {
      stack: "flex flex-col gap-2",
      inline: "flex flex-wrap gap-4",
      pill: "flex flex-wrap gap-2"
    }.freeze

    def initialize(name:, id:, options:, variant: :stack, size: nil, error: false, **attributes)
      @name = name          # already the array name: "user[tag_ids][]"
      @id = id
      @options = options    # [{ value:, label:, checked:, id: }, ...]
      @variant = variant
      @size = size
      @error = error
      @attributes = attributes
      super()
    end

    def view_template
      # Empty-array hidden field so an empty selection still submits (the same
      # convention as collection_check_boxes).
      input(type: "hidden", name: @name, value: "")

      # class is the per-checkbox styling seam (see render_checkbox), not a group
      # attribute — everything else the caller passed lands on the group so aria:,
      # data:, id: etc. pass straight through.
      div(class: group_classes, role: "group", "aria-invalid": @error || nil,
        **@attributes.except(:class)) do
        @options.each { |option| item(option) }
      end
    end

    private

    def item(option)
      label(class: item_classes) do
        render_checkbox(option)
        span(class: item_label_classes) { option[:label].to_s }
      end
    end

    # Delegate the checkbox markup to the daisyui gem so the size modifier
    # resolves to a literal class (checkbox-sm, ...) the CSS scanner can see.
    def render_checkbox(option)
      render DaisyUI::Checkbox.new(
        *checkbox_modifiers,
        name: @name, id: option[:id], value: option[:value],
        checked: option[:checked] || nil, class: @attributes[:class]
      )
    end

    def checkbox_modifiers = @size ? [@size] : []

    # --- styling seams (the Plain twin overrides these to bare/empty) ---

    def group_classes = VARIANT_CLASSES.fetch(@variant, VARIANT_CLASSES[:stack])

    def item_classes
      return "label cursor-pointer gap-2 justify-start" unless @variant == :pill

      "badge badge-lg cursor-pointer gap-2 has-[:checked]:badge-primary"
    end

    def item_label_classes = nil
  end
end
