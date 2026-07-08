# frozen_string_literal: true

module Forms
  module Live
    # A Forms::Field that merges the blur-time validate trigger into every
    # input's data attributes (via apply_validations, the seam every builder
    # already routes options through).
    class Field < Forms::Field
      def initialize(live_trigger: nil, **)
        super(**)
        @live_trigger = live_trigger
      end

      def apply_validations(options)
        merged = super
        return merged unless @live_trigger

        merged.merge(data: merge_data(merged[:data], @live_trigger[:data]))
      end

      # When THIS field is the form's declared `live_tags` field, render the
      # ROOTLESS variant: no nested reactive root, so the outer <form> DOM-owns
      # the hidden tags field and live :validate collects it. Its wire attrs were
      # hoisted onto the form root by Forms::Live#form_attributes. Any other tag
      # field falls through to the standard (self-rooted, non-live) widget.
      def tag_field(*modifiers, suggestions: [], **)
        declaration = @form.class.respond_to?(:live_tags_declaration) && @form.class.live_tags_declaration
        return super unless declaration && declaration[:name] == @name

        # Call-site suggestions win; otherwise fall back to the declaration's.
        suggestions = declaration[:suggestions] if blank_suggestions?(suggestions)
        theme[:rootless_tag_field].new(
          *modifiers,
          name: field_name, id: field_id, value: field_value,
          suggestions:, error: invalid?, **
        )
      end

      private

      def blank_suggestions?(suggestions)
        suggestions.respond_to?(:empty?) ? suggestions.empty? : suggestions.nil?
      end
    end
  end
end
