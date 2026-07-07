# frozen_string_literal: true

module Forms
  # A label for a single collection checkbox item.
  class CollectionLabel < Phlex::HTML
    def initialize(for_id:, text:, **options, &block)
      @for_id = for_id
      @text = text
      @options = options
      @block = block
      super()
    end

    def view_template
      label(for: @for_id, class: @options[:class]) do
        @block ? yield_content(&@block) : plain(@text)
      end
    end
  end
end
