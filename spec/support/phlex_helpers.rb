# frozen_string_literal: true

# Renders a block inside a minimal Phlex context that has the Forms kit mixed in,
# so bare kit helpers (Form, Input, Submit, ...) resolve exactly as they do in a
# host app that `include Forms`.
module PhlexHelpers
  class KitContext < Phlex::HTML
    include Forms

    def initialize(&block)
      @block = block
      super()
    end

    def view_template
      instance_exec(&@block)
    end
  end

  def kit(&)
    render KitContext.new(&)
  end
end
