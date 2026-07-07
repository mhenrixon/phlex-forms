# frozen_string_literal: true

module PhlexForms
  # Central configuration for phlex-forms. Set via `PhlexForms.configure`.
  #
  #   PhlexForms.configure do |c|
  #     c.icon_renderer = ->(name, **opts) { MyIcons::Icon.new(name, **opts) }
  #   end
  #
  # The icon renderer is a callable `->(name, **opts) { renderable }` returning
  # something a Phlex component can emit: a Phlex component instance OR a raw SVG
  # String.
  #
  # The DEFAULT is a bundled inline SVG so phlex-forms is self-contained and
  # renders identically with no host configuration. To use the glyphs gem (which
  # resolves a full icon set from the host app's rails_icons asset tree), opt in:
  #
  #   PhlexForms.configure do |c|
  #     c.icon_renderer = PhlexForms::Configuration.glyphs_renderer
  #   end
  #
  # glyphs is intentionally NOT the default: rails_icons reads SVGs from the host
  # app's asset paths, which a minimal host (or the gem's own test suite) has not
  # set up — so defaulting to glyphs would raise Icons::IconNotFound.
  class Configuration
    # A ready-made renderer that delegates to glyphs' LucideIcon. Raises a clear
    # error if glyphs is not loaded.
    def self.glyphs_renderer
      unless defined?(Glyphs::LucideIcon)
        raise PhlexForms::FeatureUnavailable,
          "PhlexForms glyphs_renderer requires the `glyphs` gem to be loaded"
      end

      ->(name, **opts) { Glyphs::LucideIcon.new(name, **opts) }
    end

    attr_writer :icon_renderer

    def icon_renderer
      @icon_renderer ||= ->(name, **opts) { InlineIcons.render(name, **opts) }
    end

    # Returns a renderable for the named icon. Components pass the result to Phlex
    # `render`/`raw` as appropriate.
    def render_icon(name, **)
      icon_renderer.call(name.to_s, **)
    end
  end
end
