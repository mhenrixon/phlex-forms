# frozen_string_literal: true

# Tag fields — field :tags, as: :tags. A model-bound tag/chip input composed from
# phlex-reactive's client-only tag primitives.
class Views::Docs::Pages::TagFields < DocsUI::Page
  title "Tag fields"
  eyebrow "Guide"

  def lead = "field :tags, as: :tags renders a polished tag/chip input — daisyUI chrome over phlex-reactive's client-only tag primitives, submitting one comma-joined param."

  def content
    the_idea
    live_example
    suggestions
    the_model
    theme_parity
    live_forms
    constraints
  end

  private

  def the_idea
    DocsUI::Section("A tag input, written once") do
      md <<~'MD'
        `as: :tags` renders a tag/chip input: type-ahead over your suggestions,
        Enter or click to add a chip, × to remove — all client-side (form state,
        no server round trips). phlex-forms owns the polished chrome (label,
        error/hint, daisyUI styling, model binding); the behavior rides on
        [phlex-reactive](https://phlex-reactive.zoolutions.llc)'s tag primitives.

        **Requires phlex-reactive ≥ 0.11.4** — the `:tags` control is only
        registered when it's loaded.
      MD
      DocsUI::Code(<<~'RUBY')
        f.field :tags, as: :tags, suggestions: %w[Ruby Rails Hotwire Postgres]
      RUBY
    end
  end

  def live_example
    DocsUI::Section("Try it") do
      md <<~'MD'
        The widget below is the real `Forms::TagField`, rendered live on this
        page. Type to filter the suggestions, Enter or click to add a tag, × to
        remove one. The hidden field (inspect it) carries the comma-joined value.
      MD
      div(class: "not-prose my-4 p-4 rounded-box border border-base-300 bg-base-100") do
        render Forms::TagField.new(
          name: "post[tags]", id: "demo_post_tags", value: %w[Ruby Rails],
          suggestions: %w[Ruby Rails Hotwire Postgres Stimulus Turbo Phlex Kamal]
        )
      end
    end
  end

  def suggestions
    DocsUI::Section("Suggestions: Array or haystack Hash") do
      md <<~'MD'
        Pass an **Array** of tags, or a **Hash** of `tag => haystack` where the
        haystack is the synonym text the type-ahead filter matches against — so
        typing "db" surfaces "Postgres".
      MD
      DocsUI::Code(<<~'RUBY')
        # plain list — the filter matches the tag text
        f.field :tags, as: :tags, suggestions: %w[Ruby Rails Hotwire]

        # haystack Hash — the filter matches the synonyms, the chip shows the tag
        f.field :tags, as: :tags, suggestions: {
          "Postgres" => "postgres database db sql",
          "Redis"    => "redis cache kv key value"
        }
      RUBY
    end
  end

  def the_model
    DocsUI::Section("The model splits the comma-joined value") do
      md <<~'MD'
        The widget submits **one comma-joined param** (`post[tags] =
        "Ruby,Rails"`) — the primitive's wire contract. The visible type-ahead
        input carries **no `name`**, so it never posts a stray param; only a
        hidden field does. Have the model split the string back into an array:
      MD
      DocsUI::Code(<<~'RUBY', filename: "app/models/post.rb")
        class Post < ApplicationRecord
          attribute :tags, default: []          # a text[] / JSONB column, say

          # accept the widget's "Ruby,Rails" and a normal Array alike
          def tags=(value)
            super(value.is_a?(String) ? value.split(",").map(&:strip).reject(&:empty?) : value)
          end
        end
      RUBY
      DocsUI::Callout(:note) do
        md <<~'MD'
          A future release may ship the split writer (or an `ActiveModel::Type`)
          so `field :tags, as: :tags` works against `attribute :tags, array: true`
          with zero model code.
        MD
      end
    end
  end

  def theme_parity
    DocsUI::Section("Theme parity") do
      md <<~'MD'
        Under the plain theme the widget keeps the **entire** client wire contract
        (the tag behavior still works) but ships **zero** daisyUI classes; the
        invalid state rides `aria-invalid` on the query input. Custom styling
        overrides the leaf's class seams (`root_classes`, `chip_classes`,
        `menu_classes`, …).
      MD
    end
  end

  def live_forms
    DocsUI::Section("Validating tags in a live form") do
      md <<~'MD'
        A standalone tag widget is its own [reactive](/docs/live-validation) root,
        so inside a `live` form the outer validation root would skip its hidden
        field. Declare `live_tags` to lift the widget's wire attributes onto the
        `<form>` root and render it rootless — then the form owns the hidden field
        and `:validate` runs your real validators over the tags:
      MD
      DocsUI::Code(<<~'RUBY', filename: "app/forms/post_form.rb")
        class PostForm < Forms::Base
          live model: Post
          live_tags :tags, suggestions: %w[Ruby Rails Hotwire]

          def fields
            field :title
            field :tags, as: :tags     # renders rootless; the form validates it
            submit :primary
          end
        end
      RUBY
      md <<~'MD'
        phlex-reactive's tag controller reads **one** tag field per root, so a
        live form lifts **at most one** — a second `live_tags` raises. A second
        tag input must stay a standalone (non-live) `field :other, as: :tags`.
      MD
    end
  end

  def constraints
    DocsUI::Section("Constraints") do
      md <<~'MD'
        - **phlex-reactive ≥ 0.11.4** is required — without it the `:tags` control
          role isn't registered (the gem still boots and every other field works).
        - Tags **can't contain a comma** — it's the value separator.
        - One lifted (live-validated) tag field per form; see above.
      MD
    end
  end
end
