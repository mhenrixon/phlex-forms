# frozen_string_literal: true

# The primary verb: field(name, *modifiers, **options) — every option, the
# label/error/hint contract, and the submit button.
class Views::Docs::Pages::FieldApi < DocsUI::Page
  title "The field API"
  eyebrow "Guide"

  def lead = "field(name, *modifiers, **options) renders label + input + error/hint in one call."

  def content
    the_verb
    the_options
    labels_errors_hints
    the_submit
  end

  private

  def the_verb
    DocsUI::Section("The primary verb") do
      md <<~'MD'
        `field` wraps a labeled control around the right input for the
        attribute, wiring `name`, `id`, `value`, `required`, and the error state
        from the bound model:
      MD
      DocsUI::Code(<<~'RUBY')
        f.field :email                          # type=email, label auto, required inferred
        f.field :notify                         # boolean column → toggle
        f.field :role                           # AR enum → select, humanized
        f.field :bio, as: :textarea, rows: 6    # explicit as: always wins
        f.field :name, :primary, :lg, label: "Full name", hint: "As on your ID"
      RUBY
      md <<~'MD'
        Positional symbols are daisyUI variants (`:primary`, `:lg`, `:ghost`, …)
        stacked onto the inner input — see [Variants](/docs/variants) — or a
        type override (`:number`, `:date`, …). Remaining keywords pass through
        to the input element (`rows:`, `placeholder:`, `data:`, …).
      MD
    end
  end

  def the_options
    DocsUI::Section("Options") do
      DocsUI::Table(
        [ "Option", "Effect" ],
        [
          [ [ :code, "label:" ], "Label text. Defaults to the model's humanized attribute name. label: false omits the label." ],
          [ [ :code, "hint:" ], "Help text shown beneath the field when there is no error." ],
          [ [ :code, "as:" ], "Override the control: :select, :textarea, :toggle, :checkbox, :file, :radio, :hidden, :rich_textarea, or any text-like type." ],
          [ [ :code, "required:" ], "Force the required flag. Otherwise inferred from the model's unconditional presence validators." ],
          [ [ :code, "choices:" ], "Choices for a select — implies as: :select when given. Pairs, flat values, or a Hash (optgroups)." ],
          [ [ :code, "validate:" ], "Client-side validation override: false opts out, a Hash gives explicit rules. See Client-side validation." ]
        ]
      )
      md <<~'MD'
        Everything not listed flows to the input. Caller options always beat
        inferred attributes — pass `maxlength: 10` and the validator-derived
        `maxlength` is replaced.
      MD
    end
  end

  def labels_errors_hints
    DocsUI::Section("Labels, errors, and hints") do
      md <<~'MD'
        The label text comes from `human_attribute_name` when the model speaks
        ActiveModel, so your locale files apply. A field whose attribute has an
        unconditional presence validator renders a required marker and the
        `required` attribute.

        When the model has an error on the attribute, the field renders the
        first full message **instead of** the hint, and the input picks up the
        error variant automatically:
      MD
      DocsUI::Code(<<~'RUBY')
        f.field :email, hint: "We never spam."
        # valid:   … <p>We never spam.</p>
        # invalid: … <p>Email is invalid</p>  (input gets the error variant)
      RUBY
      DocsUI::Callout(:note) do
        plain "An inferred association select is named by the foreign key "
        code { "user[country_id]" }
        plain " but still shows errors Rails attached to "
        code { ":country" }
        plain " — both names are checked."
      end
    end
  end

  def the_submit
    DocsUI::Section("The submit button") do
      md <<~'MD'
        `submit` defaults its label from the record's persistence state via
        i18n — *Create User* for a new record, *Update User* for a persisted
        one — and takes text and variants positionally:
      MD
      DocsUI::Code(<<~'RUBY')
        f.submit                    # "Create User" / "Update User"
        f.submit :primary, :lg      # default text, variants
        f.submit "Save", :primary   # custom text + variants
      RUBY
    end
  end
end
