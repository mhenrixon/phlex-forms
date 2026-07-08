---
description: "Use when implementing any feature or fixing any bug — enforces RED-GREEN-REFACTOR: write failing test first, implement minimum code to pass, then refactor."
model: sonnet
---

# TDD Command

Enforce test-driven development with RED → GREEN → REFACTOR.

## The TDD Cycle

```text
RED:      Write a failing test (it MUST fail first)
GREEN:    Write MINIMAL code to pass (nothing more)
REFACTOR: Improve code while keeping tests green
REPEAT:   Next scenario
```

## When to Use

- Implementing a new `Forms::` leaf component or extending an existing one
- Adding a config knob to `PhlexForms::Configuration`
- Changing type inference (`PhlexForms::Inference`)
- Adding or remapping a theme role (`PhlexForms::Theme`)
- Fixing a bug (write the reproducing test FIRST)

## Workflow

### Step 1: Write Failing Tests (RED)

Pick the cheapest layer that proves the behavior. Unit specs live in
`spec/phlex_forms/**` (pure logic); integration specs live in `spec/forms/**`
and render a real form through the `render_form` / `FormContext` kit helper.
Model doubles come from the `build_model` ActiveModel helper
(`spec/support/model_helpers.rb`).

```ruby
# Config (pure, no Rails): a new configuration knob + its default
RSpec.describe PhlexForms::Configuration do
  it "defaults infer_from_model to true" do
    expect(described_class.new.infer_from_model).to be(true)
  end
end

# Inference (pure precedence logic — the highest-value unit target):
RSpec.describe PhlexForms::Inference do
  it "maps a boolean column to a toggle" do
    model = build_model(:user, notify: false)
    result = described_class.resolve(model:, name: :notify)
    expect(result.as).to eq(:toggle)
  end
end

# Theme: role resolution + `.with` overrides
RSpec.describe PhlexForms::Theme do
  it "resolves :plain to the unstyled input leaf" do
    expect(described_class.resolve(:plain)[:input]).to eq(Forms::Plain::Input)
  end
end

# Integration: the rendered markup for a model-bound field
RSpec.describe Forms::Field do
  it "renders type=email for an email attribute" do
    model = build_model(:user, email: "a@b.c")
    html = render_form(model) { |f| f.field :email }
    expect(html).to include('type="email"')
  end
end
```

### Step 2: Run — Verify FAIL

```bash
bundle exec rspec <spec_file>
# FAIL — confirms the test runs, tests the right thing, and the code doesn't already exist
```

### Step 3: Implement Minimal Code (GREEN)

### Step 4: Run — Verify PASS

```bash
bundle exec rspec <spec_file>
# N examples, 0 failures
```

### Step 5: Refactor

Improve while staying green: extract methods, improve names, reduce duplication.

### Step 6: Run Full Suite + Lint

```bash
bundle exec rspec
bundle exec rubocop lib spec
```

## Coverage Expectations

| Code | Minimum |
|------|---------|
| All code | 80% |
| `PhlexForms::Inference` (every precedence branch + the `infer_from_model` kill-switch) | ~100% |
| `PhlexForms::Configuration` (every knob + its default + override) | 100% |
| `PhlexForms::Theme` (role resolution, `.with` overrides, daisy/plain parity) | 100% |

## Best Practices

**DO:** test FIRST; verify RED; minimal GREEN; refactor green; assert on
component **semantics** (an inferred control type, a `required` flag, an
error-variant class, an inferred choices list) via a real `render_form`; build
model doubles with `build_model` so column types, enums, and validators drive
inference exactly as they would in a host app.

**DON'T:** implement before testing; assert brittle full-HTML snapshots; test
implementation details; hardcode a value a leaf should read from config; assert
against a plain object when the behavior depends on a model shape (use
`build_model` with the right attributes/validations).

## Checklist

- [ ] Tests written BEFORE implementation; RED verified
- [ ] Minimal GREEN; refactored green
- [ ] Coverage meets the bar (~100% on inference, config, theme)
- [ ] Edge cases covered (POROs falling through to the name map, `infer_from_model` off, plain-theme render)
- [ ] `bundle exec rubocop lib spec` passes
