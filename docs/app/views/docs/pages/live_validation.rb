# frozen_string_literal: true

# Forms::Live — server-truth validation over phlex-reactive.
class Views::Docs::Pages::LiveValidation < DocsUI::Page
  title "Live validation"
  eyebrow "Validation"

  def lead = "live model: User runs your real ActiveModel validators on blur — uniqueness included — and morphs errors back with focus preserved."

  def content
    the_idea
    how_it_works
    touched
    whitelists
    constraints
  end

  private

  def the_idea
    DocsUI::Section("One source of truth") do
      md <<~'MD'
        Client-side validation frameworks mirror your validators in JavaScript —
        and every mirror has a ceiling: uniqueness needs the database,
        `:if`/`:unless` need server context, custom validators don't translate,
        and every message exists twice.

        `live` takes the other path. The whole form becomes one
        [phlex-reactive](https://phlex-reactive.zoolutions.llc) component:
        leaving a field POSTs **all** form fields to a signed `:validate`
        action, the server assigns them to the model, runs the **real**
        validators, and replies with a focus-preserving morph.
      MD
      DocsUI::Code(<<~'RUBY', filename: "app/forms/user_form.rb")
        class UserForm < Forms::Base
          live model: User, debounce: 300

          def fields
            field :email                  # uniqueness validates against the real DB
            field :password
            field :password_confirmation  # cross-field confirmation just works
            submit :primary
          end
        end
      RUBY
      md <<~'MD'
        i18n is plain Rails i18n. Custom validators, `:on` contexts,
        `errors.add` from anywhere — it all works, because it *is* your model.
        **Nothing is ever persisted** by `:validate`; native submit and your
        controller stay authoritative.
      MD
    end
  end

  def how_it_works
    DocsUI::Section("How it works") do
      md <<~'MD'
        - The `<form>` element is the reactive root: it carries the signed
          identity token and a **debounced** whole-form `input` trigger.
        - Each input carries a `blur` trigger with a `_touch` param naming the
          field.
        - Identity is **state-backed**: the token signs the model's GlobalID
          when persisted (`nil` for new records) plus the touched-field list —
          tamper-proof, with zero client-side bookkeeping.
        - The endpoint rebuilds the form from its class, locates the record (or
          news up `live_model_class`), assigns a whitelisted slice, calls
          `model.validate`, and replies `morph` — Idiomorph preserves the
          focused input and its caret.
      MD
    end
  end

  def touched
    DocsUI::Section("No premature errors") do
      md <<~'MD'
        A field's error first appears when you **leave** it (blur adds it to
        the signed `touched` set) — typing in a fresh field never flashes an
        error under a half-typed value. Meanwhile the debounced input trigger
        live-updates the errors of fields you *already* touched, so fixing the
        password clears the confirmation error as you type.

        A form re-rendered after a failed submit (the classic 422) arrives with
        errors already on the model — those fields are auto-touched, so the
        standard flow shows everything.
      MD
    end
  end

  def whitelists
    DocsUI::Section("Assignment is double-whitelisted") do
      md <<~'MD'
        The action's param schema admits only the form's scope and `_touch` —
        everything else is dropped at the endpoint. In the action, the slice is
        narrowed again to the model's column/attribute names plus every
        validated attribute (and `_confirmation` twins), assigned through
        public writers on an in-memory model. Tune it per class:
      MD
      DocsUI::Code(<<~'RUBY')
        class UserForm < Forms::Base
          live model: User
          live_deny :role                       # never assign these
          # live_permit :email, :password       # or: assign ONLY these
        end
      RUBY
    end
  end

  def constraints
    DocsUI::Section("Constraints") do
      md <<~'MD'
        - `live` requires a `Forms::Base` subclass. The endpoint rebuilds the
          form from its **class** — an inline `Form(model:) { … }` block cannot
          be serialized, so `Form(live: true)` raises and says so.
        - `phlex-reactive` is a soft dependency: without it the macro raises a
          `FeatureUnavailable` with install guidance, and the
          [Stimulus fallback](/docs/client-validation) still works.
        - Collection controls (`collection_check_boxes`, multi-selects) are
          excluded from live assignment in v1.
        - Every blur/debounced input runs the full validator set — including
          uniqueness queries. The default 300ms debounce keeps that reasonable;
          raise it for hot forms.
      MD
    end
  end
end
