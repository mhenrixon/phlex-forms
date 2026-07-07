# frozen_string_literal: true

# The precedence chain field() resolves a control through, and how it degrades
# for plain objects.
class Views::Docs::Pages::Inference < DocsUI::Page
  title "Type inference"
  eyebrow "Guide"

  def lead = "field :x interrogates the bound model — as:/choices: are overrides, not requirements."

  def content
    precedence
    structure
    columns
    validator_attributes
    degradation
  end

  private

  def precedence
    DocsUI::Section("Precedence") do
      md <<~'MD'
        The control is resolved through a chain — **first hit wins**:

        1. Explicit `as:`
        2. A positional type modifier — `field :price, :number`
        3. Explicit `choices:` → `:select`
        4. **Model structure** — rich text, attachment, enum, `belongs_to`
        5. **Non-string column type** — boolean, text, dates, numerics
        6. The attribute-name map — `email` → `type=email`, `password` →
           `type=password`, `phone` → `type=tel`, …
        7. `type=text`

        The column type beats the name map because it is ground truth for the
        value's *shape*; the name map only disambiguates strings. The accepted
        degenerate case: a **text** column named `email` renders a textarea.
      MD
    end
  end

  def structure
    DocsUI::Section("Model structure") do
      DocsUI::Table(
        [ "Declaration", "Renders" ],
        [
          [ [ :code, "has_rich_text :body" ], "field :body → rich textarea" ],
          [ [ :code, "has_one_attached :avatar" ], "field :avatar → file input" ],
          [ [ :code, "has_many_attached :photos" ], "field :photos → file input, multiple, name=\"…[photos][]\"" ],
          [ [ :code, "enum :role, {…}" ], "field :role → select over humanized enum keys, round-trips the current value" ],
          [ [ :code, "belongs_to :country" ], "field :country or :country_id → select over the association" ]
        ]
      )
      md <<~'MD'
        The association select rewrites the field name to the foreign key
        (`user[country_id]`), takes its label and required flag from the
        association, and builds choices lazily from `klass.all` with the option
        text resolved through a `name` → `title` → `label` → `to_s` chain.
        Errors Rails attaches to `:country` still display.
      MD
      DocsUI::Callout(:tip) do
        plain "Association choices query per render and are unscoped. Pass "
        code { "choices:" }
        plain " to scope, order, or cache them — the explicit argument always wins."
      end
    end
  end

  def columns
    DocsUI::Section("Column types") do
      DocsUI::Table(
        [ "Column type", "Control" ],
        [
          [ [ :code, "boolean" ], "toggle (checkbox + hidden unchecked pair)" ],
          [ [ :code, "text" ], "textarea" ],
          [ [ :code, "date / datetime / time" ], "matching input type (datetime → datetime-local)" ],
          [ [ :code, "integer" ], "number, step: 1" ],
          [ [ :code, "decimal (scale n)" ], "number, step: 10⁻ⁿ" ],
          [ [ :code, "decimal / float (no scale)" ], "number, step: \"any\"" ],
          [ [ :code, "string" ], "falls through to the name map" ]
        ]
      )
    end
  end

  def validator_attributes
    DocsUI::Section("Validator-derived attributes") do
      md <<~'MD'
        Unconditional validators contribute HTML attributes, merged **under**
        caller options:

        - `length: { maximum: 30 }` → `maxlength="30"` on text-like controls,
        - `numericality: { greater_than_or_equal_to: 18, less_than_or_equal_to: 130 }`
          → `min`/`max` on number inputs (exclusive bounds map ±1 for
          `only_integer`, otherwise they're skipped),
        - a presence validator → the `required` flag and label marker.

        Validators with `:if`, `:unless`, or `:on` are skipped — they need
        server context the renderer doesn't have.
      MD
    end
  end

  def degradation
    DocsUI::Section("Degradation & the kill switch") do
      md <<~'MD'
        Every model touch sits behind `respond_to?` guards. Plain objects,
        Structs, and untyped `ActiveModel::Attributes` fall through to the
        name map — exactly the pre-inference behavior. There is no ActiveRecord
        dependency.

        To restore name-map-only inference everywhere:
      MD
      DocsUI::Code(<<~'RUBY', filename: "config/initializers/phlex_forms.rb")
        PhlexForms.configure do |c|
          c.infer_from_model = false
        end
      RUBY
    end
  end
end
