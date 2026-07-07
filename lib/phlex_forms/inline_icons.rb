# frozen_string_literal: true

module PhlexForms
  # The gem's zero-dependency fallback icon set: a small map of inline SVGs for
  # the handful of icons phlex-forms itself renders. Swap the whole renderer via
  # `PhlexForms.configure { |c| c.icon_renderer = ... }` (e.g. to use glyps).
  module InlineIcons
    # Lucide "chevron-down", 24x24, currentColor stroke — matches the icon the
    # select trigger used before extraction.
    CHEVRON_DOWN = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg>
    SVG

    ICONS = {
      "chevron-down" => CHEVRON_DOWN
    }.freeze

    module_function

    # Returns a raw SVG string with any `class:` applied to the root element.
    # The caller marks it safe for its render context (Phlex `raw(safe(...))`),
    # so this stays a plain String and the gem needs no ActiveSupport. Unknown
    # icon names return an empty string rather than raising, so a missing glyph
    # degrades gracefully.
    def render(name, **opts)
      svg = ICONS[name.to_s]
      return "" if svg.nil?

      opts[:class] ? apply_class(svg, opts[:class]) : svg
    end

    def apply_class(svg, klass)
      svg.sub("<svg ", %(<svg class="#{klass}" ))
    end
  end
end
