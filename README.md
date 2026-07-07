# phlex-forms

A model-bound, DaisyUI-styled form builder for [Phlex](https://www.phlex.fun).

`Form(model:) { |f| f.field :email }` renders a label, an input, and an
error/hint in **one call** — inferring the input type from the attribute name and
the `required` flag from the model's validations. It's built on the
[`daisyui`](https://github.com/mhenrixon/daisyui) gem, so every field is a thin
binding layer over a real DaisyUI component: positional variants stack, blocks
pass through, and the markup stays DaisyUI v5-correct.

```ruby
Form(:spaced, model: @user) do |f|
  f.field :email, hint: t("users.email_hint")      # type=email, required inferred
  f.field :role,  as: :select, choices: roles
  f.field :bio,   as: :textarea, rows: 6
  f.field :notify, as: :toggle
  f.submit :primary
end
```

## Installation

```ruby
# Gemfile
gem "phlex-forms"
```

phlex-forms exposes its components under the `Forms::` namespace as a
[Phlex::Kit](https://www.phlex.fun/kits.html). Include it wherever you render
components (typically your `ApplicationComponent` / base view):

```ruby
class ApplicationComponent < Phlex::HTML
  include Forms
end
```

Now `Form(...)`, `Submit(...)`, and every other `Forms::*` component are available
as bare kit helpers.

## The `field` API

`f.field(name, *modifiers, **options)` is the primary verb. It renders a
`form-control` wrapping a label, the input, and an error (or hint):

| Option | Effect |
| --- | --- |
| `label:` | Label text. Defaults to the model's humanized attribute name. `label: false` omits it. |
| `hint:` | Help text shown when there is no error. |
| `as:` | Override the control: `:select`, `:textarea`, `:toggle`, `:checkbox`, `:file`, `:radio`, `:hidden`, or any text-like type. |
| `required:` | Force the required flag. Otherwise inferred from the model's presence validators. |
| `choices:` | Choices for `as: :select`. |
| positional modifiers | daisyui variants — `:primary`, `:lg`, `:ghost`, … — stacked onto the input. |

Type is inferred from the attribute name (`email` → `type=email`, `password` →
`type=password`, `phone` → `type=tel`, …).

### Escape hatches

When you need full control (custom Stimulus wiring, bespoke layout), the
lower-level component methods are always available with stable signatures:

```ruby
f.Control(:email, label: "Email") do
  f.Input(:email, :primary, data: { controller: "autocomplete" })
end

f.Input(:name, :primary, :lg)     # bare input, variants stacked
f.Select(:role, choices: roles)   # native <select>
f.Textarea(:bio, :ghost)
f.Checkbox(:terms) ; f.Toggle(:notify) ; f.FileInput(:avatar)
f.Label(:email) ; f.Hidden(:token) ; f.submit("Save", :primary)
```

### Icons inside a field (DaisyUI v5)

`WrappedInput` renders the `<label class="input">{icon}{input}` pattern:

```ruby
f.field(:search).wrapped_input(:primary) do
  LucideIcon("search", class: "opacity-50")   # leading content
end
```

## Nested attributes & collections

```ruby
f.fields_for(:line_items) do |item|          # single assoc or has_many
  item.field :description
end

f.collection_check_boxes(:role_ids, Role.all, :id, :name) do |b|
  render b.check_box
  render b.label
end

f.collection_select(:country_id, Country.all, :id, :name, prompt: "Select…")
```

## Client-side validation

phlex-forms ships a Stimulus validation framework that mirrors your ActiveModel
validators — no ugly, browser-inconsistent native validation bubbles.

```ruby
Form(model: @partner, validate: true) do |f|
  f.field :title                              # every validator on :title
  f.field :slug, validate: false             # opt this field out
  f.field :note, validate: { length: { maximum: 30 } }  # explicit rules
end
```

When `validate: true`, the form gets `novalidate` and a submit coordinator; each
field emits `data-forms--validations--*` bindings introspected from the model.
Supported: presence, length (with a live counter), format, numericality,
inclusion, exclusion, confirmation, acceptance. Validators with `:if` / `:unless`
/ `:on` are skipped (they need server context); the server stays authoritative.

Register the controllers in your Stimulus setup:

```js
// app/javascript/controllers/index.js
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
lazyLoadControllersFrom("phlex_forms/controllers", application)
```

Validation messages ship for `en` / `fr` / `af`; override any string via
`window.PhlexForms.messages`.

## Icons

Icons default to a bundled inline SVG so the gem is self-contained. To use
[`glyphs`](https://rubygems.org/gems/glyphs) (rails-icons under the hood):

```ruby
PhlexForms.configure do |c|
  c.icon_renderer = PhlexForms::Configuration.glyphs_renderer
end
```

## RuboCop cops

Two cops nudge call sites toward the phlex-forms API. Enable them in your
`.rubocop.yml`:

```yaml
require:
  - phlex_forms/rubocop
inherit_gem:
  phlex-forms: config/rubocop.yml
```

- `PhlexForms/RawForm` — use `Form()` over `form_with` / raw `form()` (autocorrects).
- `PhlexForms/LegacyFormMethod` — use `form.field(...)` / the PascalCase methods
  over Rails-style `text_field` / `select` / etc.

## JavaScript peer dependencies

- `@hotwired/stimulus` — required.
- `choices.js` — only if you use searchable/multi selects (`searchable: true`).

## Companion

Form-level error summaries (`FormErrors`) live in your app's UI kit, not here —
pair them with `Form()` as you like.

## License

MIT © Mikael Henriksson
