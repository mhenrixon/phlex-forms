# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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
