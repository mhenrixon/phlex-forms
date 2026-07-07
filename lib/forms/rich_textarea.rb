# frozen_string_literal: true

module Forms
  # A rich-text editor backed by the Lexxy `<lexxy-editor>` custom element for
  # ActionText. Optional feature: requires ActionText/Lexxy in the host app.
  # Renders an editor bound to the field; when the value is an ActionText::RichText
  # its HTML body is used as the initial content.
  class RichTextarea < Phlex::HTML
    register_element :lexxy_editor

    def initialize(*modifiers, name:, id: nil, value: nil, **options)
      @modifiers = modifiers
      @name = name
      @id = id || name.to_s.gsub(/[\[\]]/, "_").gsub(/_+$/, "")
      @value = value
      @options = options
      super()
    end

    def view_template
      lexxy_editor(
        name: @name,
        id: @id,
        value: formatted_value,
        class: editor_classes,
        **@options.except(:class, :error)
      )
    end

    private

    def formatted_value
      return nil if @value.nil? || (@value.respond_to?(:blank?) && @value.blank?)

      content = @value.respond_to?(:body) ? @value.body&.to_html : @value.to_s
      content.to_s.empty? ? nil : "<div>#{content}</div>"
    end

    def editor_classes
      [@options[:class], "lexxy-content"].compact.join(" ")
    end
  end
end
