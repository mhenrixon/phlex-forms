# frozen_string_literal: true

# From a bare model to a live-validating form class, in four steps.
class Views::Docs::Pages::QuickStart < DocsUI::Page
  title "Quick start"
  eyebrow "Getting started"

  def lead = "From a model to a live-validating form class in four steps."

  def content
    the_model
    inline_form
    to_a_class
    go_live
  end

  private

  def the_model
    DocsUI::Section("Start from the model") do
      md <<~'MD'
        Everything phlex-forms infers comes from here — column types, the enum,
        the association, the validators:
      MD
      DocsUI::Code(<<~'RUBY', filename: "app/models/user.rb")
        class User < ApplicationRecord
          belongs_to :country
          enum :role, { member: 0, admin: 1 }

          validates :email, presence: true, uniqueness: true
          validates :bio, length: { maximum: 400 }
        end
      RUBY
    end
  end

  def inline_form
    DocsUI::Section("Render an inline form") do
      md <<~'MD'
        `Form(model:)` derives the scope, URL, and method from the record (POST
        for a new record, PATCH + hidden `_method` for a persisted one), emits
        the CSRF token, and yields itself as the builder:
      MD
      DocsUI::Code(<<~'RUBY', filename: "app/views/users/new.rb")
        Form(model: @user) do |f|
          f.field :email                 # type=email, required — both inferred
          f.field :role                  # enum → select: Member / Admin
          f.field :country               # belongs_to → select, name="user[country_id]"
          f.field :bio, hint: "Optional" # text column → textarea, maxlength=400
          f.submit :primary              # "Create User" / "Update User"
        end
      RUBY
      md <<~'MD'
        Each `field` call renders a labeled control with the error (when the
        model has one) or the hint beneath it. Server round-trip errors just
        work: re-render the form with the invalid record and every failed field
        shows its message.
      MD
    end
  end

  def to_a_class
    DocsUI::Section("Promote it to a form class") do
      md <<~'MD'
        The same form as a reusable, testable object — `self` is the form, so
        the `f.` prefix disappears:
      MD
      DocsUI::Code(<<~'RUBY', filename: "app/forms/user_form.rb")
        class UserForm < Forms::Base
          form_options :spaced, field_variants: [:primary]

          def fields
            field :email
            field :role
            field :country
            field :bio, hint: "Optional"
            submit :primary
          end
        end
      RUBY
      DocsUI::Code(<<~'RUBY', filename: "app/views/users/new.rb")
        render UserForm.new(model: @user)
      RUBY
      md <<~'MD'
        `form_options` defaults are inherited and merged down the subclass
        chain; instance arguments win. See [Form classes](/docs/form-classes).
      MD
    end
  end

  def go_live
    DocsUI::Section("Go live") do
      md <<~'MD'
        With `phlex-reactive` in the bundle, one macro turns the form into a
        server-truth live validator — blur a field and the **real** validators
        run (including that uniqueness check), the errors morph in, and the
        caret never moves:
      MD
      DocsUI::Code(<<~'RUBY', filename: "app/forms/user_form.rb")
        class UserForm < Forms::Base
          live model: User, debounce: 300

          def fields
            field :email
            field :role
            field :country
            field :bio, hint: "Optional"
            submit :primary
          end
        end
      RUBY
      md <<~'MD'
        Nothing is persisted by live validation — native submit and your
        controller stay authoritative. The full story (touched tracking,
        whitelists, constraints) is on [Live validation](/docs/live-validation).
      MD
    end
  end
end
