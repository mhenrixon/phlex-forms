# frozen_string_literal: true

require "spec_helper"

describe Forms::Form do
  let(:user) do
    build_model(
      :user,
      email: "a@b.c", bio: nil, role: "admin", notify: nil,
      validations: -> { validates :email, presence: true }
    )
  end

  # `render_form(model, url:) { |f| ... }` is provided by PhlexHelpers and renders
  # a real `Form(model:) { |f| ... }` through a kit context.

  describe "the Control-first #field API" do
    it "renders label + input + hint and infers type and required from the model" do
      output = render_form(user) { |f| f.field(:email, hint: "No spam") }

      expect(output).to include('<div class="form-control w-full">')
      # label with required marker (inferred from the presence validator)
      expect(output).to include("Email")
      expect(output).to include('<span class="text-error ml-1">*</span>')
      # type inferred from the attribute name; value bound; required attribute set
      expect(output).to include('type="email"')
      expect(output).to include('name="user[email]"')
      expect(output).to include('id="user_email"')
      expect(output).to include('value="a@b.c"')
      expect(output).to include("required")
      # hint rendered
      expect(output).to include("No spam")
    end

    it "renders a select when as: :select with choices" do
      output = render_form(user) do |f|
        f.field(:role, as: :select, choices: [%w[Admin admin], %w[User user]])
      end

      expect(output).to include('<select name="user[role]" id="user_role" class="select w-full">')
      expect(output).to include('<option value="admin" selected>Admin</option>')
      expect(output).to include('<option value="user">User</option>')
    end

    it "renders a textarea when as: :textarea" do
      output = render_form(user) { |f| f.field(:bio, as: :textarea, rows: 5) }

      expect(output).to include('<textarea name="user[bio]" id="user_bio" rows="5" class="textarea w-full">')
    end

    it "renders a toggle (with the hidden unchecked field) when as: :toggle" do
      output = render_form(user) { |f| f.field(:notify, as: :toggle) }

      expect(output).to include('<input type="hidden" name="user[notify]" value="0">')
      expect(output).to include('type="checkbox" name="user[notify]" id="user_notify" value="1" class="toggle"')
    end

    it "omits the required marker for a non-validated attribute" do
      output = render_form(user) { |f| f.field(:bio) }

      # bio has no presence validator
      expect(output).not_to include("id=\"user_bio\"\" required")
    end

    it "lets label: false suppress the label" do
      output = render_form(user) { |f| f.field(:email, label: false) }

      expect(output).not_to include("<label")
    end

    it "shows a validation error instead of the hint when the field is invalid" do
      user.errors.add(:email, "is invalid")
      output = render_form(user) { |f| f.field(:email, hint: "No spam") }

      expect(output).to include("Email is invalid")
      expect(output).not_to include("No spam")
      expect(output).to include("input-error")
    end
  end

  describe "escape-hatch component API" do
    it "renders a bare input via f.Input with an explicit modifier" do
      output = render_form(user) { |f| f.Input(:email, :primary) }

      expect(output).to include('type="email"')
      expect(output).to include("input-primary")
    end

    it "wraps custom content via f.Control" do
      output = render_form(user) do |f|
        f.Control(:email, label: "Your email") { f.Input(:email, :bordered) }
      end

      expect(output).to include("Your email")
      expect(output).to include("input-bordered")
    end
  end

  describe "form element and model binding" do
    it "derives scope, url, patch method and multipart for a persisted record" do
      persisted = build_model(:user, email: "x@y.z")
      def persisted.persisted? = true
      def persisted.to_param = "42"

      output = render_form(persisted, &:submit)

      expect(output).to include('action="/users/42"')
      expect(output).to include('<input type="hidden" name="_method" value="patch">')
      expect(output).to include('enctype="multipart/form-data"')
    end

    it "supports a polymorphic array model (scope + nested url from the array)" do
      post = build_model(:post)
      def post.persisted? = true
      def post.to_param = "7"
      comment = build_model(:comment, body: nil)

      output = render_form([post, comment]) { |f| f.field(:body) }

      # scope is the child, not "array"
      expect(output).to include('name="comment[body]"')
      # url nests under the parent
      expect(output).to include('action="/posts/7/comments"')
    end
  end

  describe "submit button" do
    it "defaults to the create label for a new record" do
      output = render_form(user) { |f| f.submit(:primary) }

      expect(output).to include('<button type="submit" class="btn btn-primary">')
      expect(output).to include("Create User")
    end
  end
end
