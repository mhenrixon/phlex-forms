# frozen_string_literal: true

require "phlex"
require "daisy_ui"
require "tailwind_merge"
require "zeitwerk"

require_relative "phlex_forms/version"

# phlex-forms exposes its components under the `Forms::` namespace (Form, Input,
# Select, Submit, Label, ...) so that consuming apps can `include Forms` and call
# `Form(model:) { |f| ... }` as a Phlex::Kit helper. Gem-internal machinery
# (configuration, the icon renderer) lives under `PhlexForms::` to keep the
# `Forms::` namespace clean for components only.
module PhlexForms
  class Error < StandardError; end

  # Raised when an optional feature (e.g. rich text via ActionText/Lexxy) is
  # used but its backing dependency is not available.
  class FeatureUnavailable < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    alias config configuration

    def configure
      yield(configuration)
    end

    # Reset configuration to defaults. Intended for test isolation.
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

# The component namespace. Extending Phlex::Kit makes every `Forms::Foo`
# component callable as a bare `Foo(...)` helper wherever `Forms` is included.
module Forms
  extend Phlex::Kit
end

# Two non-overlapping autoload roots:
#   lib/phlex_forms/**        (minus components) -> PhlexForms::  (gem internals)
#   lib/phlex_forms/components -> Forms::                          (components)
# We drive the loader manually (not `for_gem`) so the component root can map
# onto the top-level `Forms` module while gem internals stay under `PhlexForms`.
loader = Zeitwerk::Loader.new
loader.tag = "phlex-forms"
loader.inflector.inflect(
  "phlex_forms" => "PhlexForms",
  "phlex-forms" => "PhlexForms"
)

components_dir = "#{__dir__}/phlex_forms/components"

# Gem internals under PhlexForms::, sourced from lib/ but with the component
# subtree and the already-required entry files excluded.
loader.push_dir(__dir__)
loader.ignore(components_dir)
loader.ignore("#{__dir__}/phlex-forms.rb")
loader.ignore("#{__dir__}/phlex_forms.rb")
loader.ignore("#{__dir__}/rubocop") # cops load on demand via the host .rubocop.yml
# The engine is conditionally required at the bottom of this file (only under
# Rails), so it must not be autoloaded/eager-loaded by Zeitwerk.
loader.ignore("#{__dir__}/phlex_forms/engine.rb")

# Components under the top-level Forms:: namespace.
loader.push_dir(components_dir, namespace: Forms)

loader.setup

# Optional Rails integration (Stimulus controllers via importmap/assets, and
# the gem's default locale files). Loaded only under Rails; the gem stays pure
# Phlex otherwise.
require_relative "phlex_forms/engine" if defined?(Rails::Engine)
