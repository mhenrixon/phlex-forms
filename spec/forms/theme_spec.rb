# frozen_string_literal: true

require "spec_helper"

describe "theming" do
  after { PhlexForms.reset_configuration! }

  let(:user) do
    build_model(
      :user,
      email: "a@b.c", notify: nil, role: "admin",
      validations: lambda {
        validates :email, presence: true
        attribute :notify, :boolean
      }
    )
  end

  it "defaults to the daisy theme when DaisyUI is loaded" do
    output = render_form(user) { |f| f.field(:email) }

    expect(output).to include("form-control")
    expect(output).to include('class="input')
  end

  it "renders a full form with zero styling classes under the plain theme" do
    user.errors.add(:email, "is invalid")

    output = render_form(user, theme: :plain) do |f|
      f.field(:email, hint: "No spam")
      f.submit
    end

    expect(output).to include('name="user[email]"')
    expect(output).to include('value="a@b.c"')
    expect(output).to include("required")
    expect(output).to include("aria-invalid")
    expect(output).to include('<p role="alert" data-field-error>Email is invalid</p>')
    expect(output).to match(/<button[^>]*type="submit"/)
    expect(output).to include("Create User")
    expect(output).not_to include('class="')
  end

  it "renders selects, toggles, rows, and groups plainly with binding intact" do
    output = render_form(user, theme: :plain) do |f|
      f.field(:role, choices: [%w[Admin admin], %w[User user]])
      f.field(:notify)
      f.group(legend: "Prefs") { f.row { f.field(:email) } }
    end

    expect(output).to include('<option value="admin" selected>Admin</option>')
    expect(output).to include('<input type="hidden" name="user[notify]" value="0">')
    expect(output).to match(/<input[^>]*type="checkbox"/)
    expect(output).to include("<fieldset><legend>Prefs</legend>")
    expect(output).to include("<div data-form-row>")
    expect(output).not_to include('class="')
  end

  it "renders the same Forms::Base subclass under both themes" do
    klass = Class.new(Forms::Base) do
      def fields
        field :email, :primary
        submit :primary
      end
    end

    daisy = klass.new(model: user).call
    plain = klass.new(model: user, theme: :plain).call

    expect(daisy).to include("input-primary")
    expect(daisy).to include("btn-primary")
    expect(plain).not_to include('class="')
    expect([daisy, plain]).to all(include('name="user[email]"'))
  end

  it "applies a globally configured theme" do
    PhlexForms.configure { |c| c.theme = :plain }

    output = render_form(user) { |f| f.field(:email) }

    expect(output).not_to include('class="')
  end

  it "supports single-role overrides via Theme#with" do
    custom_input = Class.new(Forms::Plain::Input) do
      def view_template
        input(type: @type, value: @value.to_s, **unstyled_attributes, class: "custom-input")
      end
    end
    theme = PhlexForms::Theme.resolve(:plain).with(input: custom_input)

    output = render_form(user, theme:) { |f| f.field(:email) }

    expect(output).to include('class="custom-input"')
  end
end
