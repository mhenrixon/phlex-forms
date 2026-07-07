# frozen_string_literal: true

module Forms
  # Yielded for each item by Form#collection_check_boxes. Provides check_box and
  # label builders mirroring Rails' collection_check_boxes API.
  class CollectionCheckBoxBuilder
    attr_reader :object, :value, :text

    def initialize(object:, value:, text:, checked:, name:, id:)
      @object = object
      @value = value
      @text = text
      @checked = checked
      @name = name
      @id = id
    end

    def check_box(options = {})
      Forms::CollectionCheckBox.new(name: @name, id: @id, value: @value, checked: @checked, **options)
    end

    def label(options = {}, &)
      Forms::CollectionLabel.new(for_id: @id, text: @text, **options, &)
    end
  end
end
