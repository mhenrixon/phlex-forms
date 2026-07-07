# frozen_string_literal: true

# Wraps a field in the daisyui form-control layout: optional label on top, the
# field (yielded block), then an error (if present) or a hint. This is the
# workhorse behind the Control-first `f.field` API and the explicit `f.Control`
# escape hatch.
module Forms
  class FormControl < Forms::Base
    def initialize(*, label: nil, hint: nil, error: nil, for: nil, required: false, **)
      super(*, **)
      @label = label
      @hint = hint
      @error = error
      @field_id = grab(for:)
      @required = required
    end

    def view_template(&)
      div(class: control_classes, **options.except(:class)) do
        render Forms::Label.new(text: @label, for: @field_id, required: @required) if @label

        yield if block_given?

        if @error
          render Forms::FieldError.new(message: @error)
        elsif @hint
          render Forms::FieldHint.new(text: @hint)
        end
      end
    end

    private

    def control_classes
      base = %w[form-control w-full]
      base << "flex flex-row items-center gap-4" if modifiers.include?(:horizontal)
      merge_classes(base.join(" "), options[:class])
    end

    register_modifiers(horizontal: nil)
  end
end
