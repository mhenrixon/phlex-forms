# frozen_string_literal: true

module Forms
  # A model-bound tag/chip input, composed from phlex-reactive's CLIENT-ONLY tag
  # primitives (form state, no token, zero round trips). phlex-forms owns the
  # polished chrome — daisyUI styling, model binding, the hidden comma-joined
  # field — while phlex-reactive owns the behavior contract.
  #
  #   f.field :tags, as: :tags, suggestions: %w[Ruby Rails Hotwire Postgres]
  #   f.field :tags, as: :tags, suggestions: { "Postgres" => "postgres database db sql" }
  #
  # Submits ONE comma-joined param (`user[tags] = "Ruby,Rails"`), the primitive's
  # wire contract — the model splits it (an `attribute :tags` + a `tags=` writer,
  # or an ActiveModel array type).
  #
  # This file is autoloaded ONLY when Phlex::Reactive is present (the Forms::Live
  # gate in lib/phlex_forms.rb) because it includes ClientBindings at class level.
  #
  # It emits the RAW `data-reactive-*` wire attributes rather than the
  # reactive_tags/reactive_filter symbol sugar: the helpers compile a SYMBOL
  # through the component's class-level reactive_scope, but a form builder's wire
  # name is per-instance ("user[tags]"). The data attributes ARE the public
  # contract; any CSS selector works (issue #6 Caveats 1 & 2).
  class TagField < Phlex::HTML
    include Phlex::Reactive::ClientBindings

    def initialize(*modifiers, name:, id:, value: nil, suggestions: [], error: false,
                   placeholder: "Add a tag…", **attributes)
      @modifiers = modifiers
      @name = name # "user[tags]" — instance-dynamic
      @id = id
      @value = value.is_a?(Array) ? value.compact.join(",") : value.to_s
      @suggestions = normalize_suggestions(suggestions)
      @error = error
      @placeholder = placeholder
      @attributes = attributes
      super()
    end

    def view_template
      div(**mix(
        reactive_root(id: "#{@id}_widget"),
        # Raw wire attrs, not the reactive_tags/reactive_filter sugar (Caveats 1 & 2):
        # target the hidden field by [name=…] and the query input by #id (an id
        # selector means the query never submits a stray param).
        { data: {
          reactive_tags_field: %([name="#{@name}"]),
          reactive_filter_input: "##{@id}_query"
        } },
        class: root_classes
      )) do
        input(type: :hidden, name: @name, id: @id, value: @value)

        div(class: list_classes, data: { reactive_tags_list: true }) do
          current_tags.each { |tag| chip(tag) } # server-rendered first paint
        end
        template(data: { reactive_tags_template: true }) { chip }

        input(**mix(reactive_listnav, query_attributes)) # NO name → never submits

        ul(class: menu_classes) do
          @suggestions.each { |tag, haystack| suggestion(tag, haystack) }
        end
      end
    end

    private

    def normalize_suggestions(suggestions)
      return suggestions if suggestions.is_a?(Hash)

      Array(suggestions).to_h { |tag| [tag, tag.to_s.downcase] }
    end

    def current_tags = @value.split(",").map(&:strip).reject(&:empty?)

    def query_attributes
      {
        id: "#{@id}_query", type: "search", autocomplete: "off",
        placeholder: @placeholder, class: input_classes,
        "aria-invalid": @error || nil,
        data: { reactive_tags_add: true }
      }.compact
    end

    def suggestion(tag, haystack)
      li do
        button(
          type: "button",
          data: { reactive_tags_option_param: tag, reactive_filter_text: haystack }
        ) { tag }
      end
    end

    # One method, both forms: with a tag = a server-rendered chip; without = the
    # <template> prototype (the client fills the text + remove param per clone).
    def chip(tag = nil)
      span(class: chip_classes, data: { reactive_tag: tag }) do
        span(data: { reactive_tag_text: true }) { tag }
        button(
          type: "button", aria: { label: "Remove" }, class: remove_classes,
          data: { reactive_tags_remove_param: tag }
        ) { "×" }
      end
    end

    # --- styling seams (the Plain twin overrides these to bare/empty) ---

    def root_classes = "tag-field flex flex-col gap-2"
    def list_classes = "flex flex-wrap gap-1"
    def menu_classes = "menu bg-base-200 rounded-box"
    def chip_classes = "badge badge-primary gap-1"
    def remove_classes = "cursor-pointer"
    def input_classes = PhlexForms::ClassMerge.merge("input w-full", @attributes[:class])
  end
end
