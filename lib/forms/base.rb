# frozen_string_literal: true

# Base class for phlex-forms leaf input components (Input, Select, Toggle, ...).
#
# Inherits DaisyUI::Base to reuse its modifier engine (register_modifiers,
# modifier_map, the positional-symbol modifier API) but overrides class building
# to route through PhlexForms::ClassMerge so conflicting daisyui modifier
# families resolve last-one-wins.
module Forms
  class Base < DaisyUI::Base
    # Merge base classes, registered modifier classes, and a caller `class:` into a
    # single deduped string. Replaces DaisyUI::Base#merge_classes' plain join.
    def merge_classes(*parts)
      PhlexForms::ClassMerge.merge(*parts)
    end

    private

    # The CSS classes contributed by the positional modifiers registered on this
    # component (e.g. :primary -> "input-primary").
    def registered_modifier_classes
      modifiers.filter_map { |m| self.class.modifiers[m] }
    end

    # Render the configured icon (component instance or raw SVG string) inline.
    def render_icon(name, **)
      icon = PhlexForms.config.render_icon(name, **)
      icon.is_a?(String) ? raw(safe(icon)) : render(icon)
    end

    # Phlex blocks boolean-false attributes from rendering; some HTML boolean attrs
    # (disabled, required, checked) must be omitted when false and bare when true.
    def bool_attr(value)
      value ? true : nil
    end
  end
end
