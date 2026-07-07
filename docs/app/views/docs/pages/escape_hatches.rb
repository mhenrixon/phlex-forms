# frozen_string_literal: true

# The PascalCase component API and the custom-widget recipe.
class Views::Docs::Pages::EscapeHatches < DocsUI::Page
  title "Escape hatches"
  eyebrow "Reference"

  def lead = "When field's one-call convenience isn't enough: bare components, wrapped inputs, and the custom-widget recipe."

  def content
    bare_components
    custom_widgets
    wrapped_inputs
    specialised
  end

  private

  def bare_components
    DocsUI::Section("The component API") do
      md <<~'MD'
        Every control `field` composes is also callable directly, with stable
        signatures — a bare input, no label/control wrapper, still fully
        model-bound:
      MD
      DocsUI::Code(<<~'RUBY')
        f.Input(:name, :primary, :lg)     # bare input, variants stacked
        f.Select(:role, choices: roles)   # native <select>
        f.Textarea(:bio, :ghost)
        f.Checkbox(:terms)
        f.Toggle(:notify)
        f.Radio(:size, "large")
        f.FileInput(:avatar)
        f.Hidden(:token)
        f.Label(:email)
        f.Control(:email, label: "Email") { f.Input(:email) }
      RUBY
      md <<~'MD'
        PascalCase marks the component layer; lowercase `field`/`row`/`group`/
        `submit` are the composed verbs. Both apply the model's value, error
        state, and client-validation data the same way.
      MD
    end
  end

  def custom_widgets
    DocsUI::Section("The custom-widget recipe") do
      md <<~'MD'
        A bespoke widget — date picker, tag field, remote select — wraps in
        `Control` and binds through the three public helpers. This is the
        supported path, not a fork reason:
      MD
      DocsUI::Code(<<~'RUBY')
        f.Control(:starts_at, label: "Starts") do
          render MyDatePicker.new(
            name: f.field_name(:starts_at),
            id: f.field_id(:starts_at),
            value: f.field_value(:starts_at)
          )
        end
      RUBY
      md <<~'MD'
        The control contributes the label, error/hint slot, and layout; your
        widget owns the input. Errors on the attribute render exactly like any
        other field's.
      MD
    end
  end

  def wrapped_inputs
    DocsUI::Section("Icons inside the field") do
      md <<~'MD'
        `wrapped_input` renders the daisyUI v5 `<label class="input">` pattern —
        leading content (an icon, a prefix), the bare input, optional trailing
        content:
      MD
      DocsUI::Code(<<~'RUBY')
        f.field_object(:search).wrapped_input(:primary) do
          LucideIcon("search", class: "opacity-50")
        end
      RUBY
      md <<~'MD'
        Icons default to a bundled inline SVG so the gem is self-contained; see
        [Configuration](/docs/configuration) for the glyphs renderer.
      MD
    end
  end

  def specialised
    DocsUI::Section("Specialised controls") do
      md <<~'MD'
        - `f.Select(:tags, choices:, searchable: true, multiple: true)` — a
          choices.js-backed searchable/multi select (needs the `choices.js`
          peer).
        - `f.rich_textarea(:body)` — the rich-text editor binding
          (ActionText-compatible value handling).
        - `f.time_zone_select(:time_zone)` — grouped time zones with a sensible
          selected default.
      MD
    end
  end
end
