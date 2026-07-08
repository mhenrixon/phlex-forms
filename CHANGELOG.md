# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **`Forms::Base` declarative form classes**: subclass, declare fields in
  `#fields` where `self` IS the form (bare `field :email`, no `f.` prefix),
  render with `render UserForm.new(model: @user)`. Class-level `form_options`
  defaults are inherited and merged down the subclass chain; a render-time
  block appends after the declared fields.
- **`live` server-truth validation** (`Forms::Base` only, phlex-reactive soft
  dependency): `live model: User` runs the real ActiveModel validators
  server-side on blur/debounced input — uniqueness, `:if`/`:unless`,
  confirmation, `:on` context — and morphs errors back in with focus
  preserved. Touched-field tracking rides the signed reactive state; nothing
  is persisted. Inline `Form(live: true)` raises with guidance.
- **Model-driven type inference** in `field`: boolean column → toggle, AR enum
  → humanized select, non-polymorphic `belongs_to` → association select (name
  rewritten to the foreign key, errors still surface from the association
  name), text column → textarea, date/datetime/time/numeric columns → matching
  inputs (+`step`), `has_rich_text` → rich textarea, attachments → file
  (`multiple` + `name[]` for `has_many_attached`), length/numericality
  validators → `maxlength`/`min`/`max`. Explicit `as:`/`choices:`/positional
  type modifiers always win; POROs and untyped models behave exactly as
  before. Kill-switch: `PhlexForms.config.infer_from_model = false`.
- `choices:` without `as: :select` now implies a select (previously silently
  dropped).
- **Themes**: component roles resolve through `PhlexForms::Theme`. The daisy
  theme (default when the daisyui gem is loaded) is unchanged; the new Plain
  theme renders bare semantic HTML — same binding contract, variants accepted
  and ignored, `aria-invalid` + `role="alert"` + `data-field-error/hint`
  hooks, zero styling classes — so the same form class renders in non-daisyui
  projects. Select per form (`theme:`), per class (`form_options theme:`), or
  globally; override single roles with `Theme#with`.
- **Form-level variant defaults**: `field_variants: [:primary, :sm]` on a
  form / `form_options` / `PhlexForms.config.field_variants` prepends daisyui
  variants to every `field`'s inner input (call-site modifiers stack last).
- Layout helpers: `f.row(columns:)` (responsive grid) and `f.group(legend:)`
  (fieldset), available on inline forms and `fields_for` builders.
- Adoption enablers: `Form(scope: false)` emits bare field names (reactive row
  editors, `<template>` rows); `fields_for(..., nested_attributes: false)`
  skips the `_attributes` suffix (JSONB columns); public `Form#field_value`
  joins `field_name`/`field_id` for external widgets.

### Changed

- **Minimum Ruby is now 3.4** (was 3.2). The optional `live` validation runs on
  phlex-reactive, which has required Ruby >= 3.4 since its 0.9 line; aligning the
  floor keeps the whole gem installable wherever the live integration is.
- **`daisyui` is now a soft dependency** (removed from the gemspec). With it
  loaded nothing changes; without it the Plain theme is the default and the
  gem renders unstyled semantic HTML.
- **Live validation is compatible with phlex-reactive >= 0.11's default-ON
  `verify_authorized` (#168).** The `:validate` action declares
  `skip_verify_authorized` — it's a no-persist, read-only validation pass, so it
  needs no authorization call and won't raise `AuthorizationNotVerified`. No host
  action required.
- Model-driven inference changes rendered output for ActiveRecord-backed
  forms that previously fell through to a text input. Before/after:

  | field on an AR model | before | after |
  | --- | --- | --- |
  | boolean column | `<input type="text">` | toggle (checkbox + hidden pair) |
  | text column | `<input type="text">` | `<textarea>` |
  | AR enum | text input | `<select>` with humanized options |
  | `belongs_to` (`:country`/`:country_id`) | text input | `<select>` over the association, `name="…[country_id]"` |
  | date/datetime/time column | text input (unless name-mapped) | matching input type |
  | integer/decimal/float column | text input | `<input type="number" step=…>` |
  | attachment / rich text | text input | file input / rich textarea |

  Pass `as:` explicitly or set `PhlexForms.config.infer_from_model = false`
  to keep the old rendering.

### Initial extraction

- Initial extraction of the `Forms::` Phlex form builder from the Cosmos apps.
- Control-first builder API: `f.field :email, label:, hint:, as:, choices:`
  renders label + input + error/hint in one call, inferring input type and the
  `required` flag from the model.
- Escape-hatch component API preserved: `f.Input`, `f.Select`, `f.Textarea`,
  `f.Checkbox`, `f.Toggle`, `f.FileInput`, `f.Hidden`, `f.Label`, `f.Control`,
  `f.submit`.
- Configurable icon renderer (`PhlexForms.configure`) with a zero-dependency
  inline-SVG default and optional `glyps` auto-detection.
- Polymorphic array model support in `Form(model: [parent, child])`.
- Bundled Stimulus controllers (choices, searchable-select, time zone) and
  default `en`/`sv`/`de` locales, wired through an optional Rails engine.
