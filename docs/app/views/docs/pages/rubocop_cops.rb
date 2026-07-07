# frozen_string_literal: true

# The two shipped cops that nudge call sites toward the phlex-forms API.
class Views::Docs::Pages::RubocopCops < DocsUI::Page
  title "RuboCop cops"
  eyebrow "Reference"

  def lead = "Two shipped cops keep call sites on the phlex-forms API — one autocorrects."

  def content
    setup
    raw_form
    legacy_form_method
  end

  private

  def setup
    DocsUI::Section("Setup") do
      DocsUI::Code(<<~'YAML', filename: ".rubocop.yml")
        require:
          - phlex_forms/rubocop
        inherit_gem:
          phlex-forms: config/rubocop.yml
      YAML
    end
  end

  def raw_form
    DocsUI::Section("PhlexForms/RawForm") do
      md <<~'MD'
        Flags `form_with`/`form_for` and raw Phlex `form(...)` calls in
        components, autocorrecting to `Form(...)` so every form gets the
        derived action/method, CSRF handling, and the builder API:
      MD
      DocsUI::Code(<<~'RUBY')
        # bad
        form(action: users_path, method: :post) { ... }

        # good (autocorrected)
        Form(url: users_path, method: :post) { |f| ... }
      RUBY
    end
  end

  def legacy_form_method
    DocsUI::Section("PhlexForms/LegacyFormMethod") do
      md <<~'MD'
        Flags Rails-FormBuilder-style calls (`f.text_field`, `f.select`,
        `f.check_box`, …) in favor of `f.field` and the PascalCase component
        methods — the biggest lever when migrating an app off a vendored
        builder:
      MD
      DocsUI::Code(<<~'RUBY')
        # bad
        f.text_field :email
        f.check_box :terms

        # good
        f.field :email          # or f.Input(:email) for the bare control
        f.Checkbox(:terms)
      RUBY
    end
  end
end
