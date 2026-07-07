# frozen_string_literal: true

# Renders a block inside a minimal Phlex context that has the Forms kit mixed in,
# so bare kit helpers (Form, Input, Submit, ...) resolve exactly as they do in a
# host app that `include Forms`.
#
# Phlex 2 delivers a component's block to `view_template` via `yield` (not a
# block captured in `initialize`), so the context yields to the given block and
# runs it in its own scope.
module PhlexHelpers
  class KitContext < Phlex::HTML
    include Forms

    def view_template(&)
      instance_exec(&)
    end
  end

  def kit(&)
    KitContext.new.call(&)
  end

  # Render a Forms::Form for `model` through a kit context, yielding the builder
  # to `form_block` exactly as `Form(model:) { |f| ... }` does in a host app.
  class FormContext < Phlex::HTML
    include Forms

    def initialize(model:, form_args:, form_block:)
      @model = model
      @form_args = form_args
      @form_block = form_block
      super()
    end

    def view_template
      Form(model: @model, **@form_args, &@form_block)
    end
  end

  def render_form(model, **form_args, &form_block)
    FormContext.new(model:, form_args:, form_block:).call
  end
end
