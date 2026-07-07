# frozen_string_literal: true

module PhlexForms
  # Central configuration for phlex-forms. Set via `PhlexForms.configure`.
  #
  #   PhlexForms.configure do |c|
  #     c.icon_renderer = ->(name, **opts) { Glyps::LucideIcon(name, **opts) }
  #   end
  #
  # By default the gem renders a small set of bundled inline SVGs (currently just
  # "chevron-down") so it has zero required icon dependency. If the `glyps` gem
  # is loaded and no custom renderer is set, glyps is auto-detected.
  class Configuration
    # A callable `->(name, **opts) { html_safe_svg_string }`.
    attr_writer :icon_renderer

    def icon_renderer
      @icon_renderer ||= default_icon_renderer
    end

    # Render an icon to an HTML-safe string. Components call this rather than the
    # renderer directly so the default/auto-detection logic stays in one place.
    def render_icon(name, **)
      icon_renderer.call(name.to_s, **)
    end

    private

    def default_icon_renderer
      if glyps_available?
        ->(name, **opts) { Glyps::LucideIcon(name, **opts) }
      else
        InlineIcons.method(:render)
      end
    end

    def glyps_available?
      defined?(Glyps) && Glyps.respond_to?(:LucideIcon)
    end
  end
end
