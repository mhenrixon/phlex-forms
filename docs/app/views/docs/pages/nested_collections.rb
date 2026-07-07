# frozen_string_literal: true

# fields_for, collections, and the unscoped/JSONB escape valves.
class Views::Docs::Pages::NestedCollections < DocsUI::Page
  title "Nested & collections"
  eyebrow "Reference"

  def lead = "Nested attributes, collection inputs, and the escape valves dynamic forms need."

  def content
    fields_for
    jsonb_mode
    collections
    unscoped
  end

  private

  def fields_for
    DocsUI::Section("Nested attributes: fields_for") do
      md <<~'MD'
        `fields_for` yields a builder per association (single) or per item
        (has_many), with the correctly-indexed `_attributes` scope Rails'
        `accepts_nested_attributes_for` expects:
      MD
      DocsUI::Code(<<~'RUBY')
        f.fields_for(:line_items) do |item|
          item.field :description        # name="invoice[line_items_attributes][0][description]"
          item.field :quantity
        end
      RUBY
      md <<~'MD'
        The nested builder speaks the full field API — `field`, `row`, escape
        hatches, even further nesting — and inherits the parent form's theme
        and variants.
      MD
    end
  end

  def jsonb_mode
    DocsUI::Section("JSONB / hash columns") do
      md <<~'MD'
        For a hash-backed column that isn't a Rails nested-attributes
        association, `nested_attributes: false` nests under the **raw** name —
        no `_attributes` suffix:
      MD
      DocsUI::Code(<<~'RUBY')
        f.fields_for(:settings, nested_attributes: false) do |s|
          s.field :locale                # name="user[settings][locale]"
        end
      RUBY
    end
  end

  def collections
    DocsUI::Section("Collection inputs") do
      DocsUI::Code(<<~'RUBY')
        f.collection_check_boxes(:role_ids, Role.all, :id, :name) do |b|
          render b.check_box
          render b.label
        end

        f.collection_select(:country_id, Country.all, :id, :name, prompt: "Select…")
      RUBY
      md <<~'MD'
        `collection_check_boxes` emits the hidden empty field so an empty
        selection still submits, and yields a builder per item with `check_box`
        and `label` prewired. For a `belongs_to`, remember
        [inference](/docs/inference) renders the association select from a bare
        `field :country` — `collection_select` is for the explicit cases.
      MD
    end
  end

  def unscoped
    DocsUI::Section("Unscoped mode & external widgets") do
      md <<~'MD'
        Dynamic rows — phlex-reactive per-row editors, `<template>`-cloned
        rows — need **bare** field names the model scope would break.
        `scope: false` turns scoping off (while `scope: nil` still derives from
        the model):
      MD
      DocsUI::Code(<<~'RUBY')
        Form(model: @item, scope: false, url: item_path(@item)) do |f|
          f.field :quantity              # name="quantity"
        end
      RUBY
      md <<~'MD'
        External widgets bind through the public helpers — the same three the
        [custom-widget recipe](/docs/escape-hatches) uses:
      MD
      DocsUI::Code(<<~'RUBY')
        f.field_name(:starts_at)   # "event[starts_at]"
        f.field_id(:starts_at)     # "event_starts_at"
        f.field_value(:starts_at)  # the model's current value
      RUBY
    end
  end
end
