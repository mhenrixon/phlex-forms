# frozen_string_literal: true

# Forms::Base: declarative form classes with inherited defaults.
class Views::Docs::Pages::FormClasses < DocsUI::Page
  title "Form classes"
  eyebrow "Guide"

  def lead = "Subclass Forms::Base, declare fields where self IS the form, render it anywhere."

  def content
    the_shape
    form_options
    render_time_block
    testing
  end

  private

  def the_shape
    DocsUI::Section("The shape") do
      md <<~'MD'
        A form class subclasses `Forms::Base` and implements one hook —
        `#fields`. Inside it, `self` is the form, so the whole builder surface
        (`field`, `row`, `group`, `Input`, `submit`, `fields_for`, …) is
        available as bare calls:
      MD
      DocsUI::Code(<<~'RUBY', filename: "app/forms/user_form.rb")
        class UserForm < Forms::Base
          def fields
            field :email
            row do
              field :first_name
              field :last_name
            end
            submit :primary
          end
        end
      RUBY
      DocsUI::Code(<<~'RUBY')
        render UserForm.new(model: @user)
      RUBY
      md <<~'MD'
        The class renders `Form`'s full chrome — derived action/method, CSRF
        token, method override, multipart encoding — then your declared fields.
        A subclass without `#fields` raises `NotImplementedError`.
      MD
    end
  end

  def form_options
    DocsUI::Section("Inherited defaults: form_options") do
      md <<~'MD'
        `form_options` sets class-level defaults — positional form modifiers and
        any keyword `Form` accepts. They are **inherited and merged** down the
        subclass chain: a child's defaults beat its parent's, and instance
        arguments beat both.
      MD
      DocsUI::Code(<<~'RUBY', filename: "app/forms/application_form.rb")
        class ApplicationForm < Forms::Base
          form_options :spaced, field_variants: [:primary]
        end

        class AdminForm < ApplicationForm
          form_options theme: :plain          # merged over the parent's
        end

        AdminForm.new(model: record, url: "/override")  # instance args win
      RUBY
    end
  end

  def render_time_block
    DocsUI::Section("The render-time block") do
      md <<~'MD'
        A block passed at render time appends **after** the declared fields —
        handy for a page-specific hidden field or an extra action without
        subclassing:
      MD
      DocsUI::Code(<<~'RUBY')
        render UserForm.new(model: @user) do |f|
          f.Hidden(:return_to)
        end
      RUBY
    end
  end

  def testing
    DocsUI::Section("Testing form classes") do
      md <<~'MD'
        A form class is a Phlex component — `#call` renders it to a string with
        no controller, no request, no view context:
      MD
      DocsUI::Code(<<~'RUBY', filename: "spec/forms/user_form_spec.rb")
        it "renders the email field bound to the model" do
          output = UserForm.new(model: User.new(email: "a@b.c")).call

          expect(output).to include('name="user[email]"')
          expect(output).to include('value="a@b.c"')
        end
      RUBY
    end
  end
end
