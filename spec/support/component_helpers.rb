# frozen_string_literal: true

# Render a Phlex component to an HTML string. Named `render_component` (not
# `render`) so it does not shadow Phlex's own instance-level `render` inside
# component/kit contexts used by specs.
module ComponentHelpers
  def render_component(component, &)
    component.call(&)
  end
end
