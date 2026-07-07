# frozen_string_literal: true

# Render a Phlex component to an HTML string. Phlex 2 components respond to
# `#call`, which returns the rendered markup.
module ComponentHelpers
  def render(component, &)
    component.call(&)
  end
end
