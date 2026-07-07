# frozen_string_literal: true

require "spec_helper"

describe Forms::Base do
  let(:user) do
    build_model(
      :user,
      email: "a@b.c", first_name: nil, last_name: nil,
      validations: -> { validates :email, presence: true }
    )
  end

  let(:form_class) do
    Class.new(Forms::Base) do
      def fields
        field :email
        row do
          field :first_name
          field :last_name
        end
        submit :primary
      end
    end
  end

  it "renders the form chrome plus the declared fields — self IS the form" do
    output = form_class.new(model: user).call

    expect(output).to include("<form")
    expect(output).to include('name="user[email]"')
    expect(output).to include('type="email"')
    expect(output).to include("grid grid-cols-1")
    expect(output).to include('name="user[first_name]"')
    expect(output).to include("Create User")
  end

  it "raises NotImplementedError when #fields is not defined" do
    expect { Class.new(described_class).new(model: user).call }
      .to raise_error(NotImplementedError, /must define #fields/)
  end

  it "applies class-level form_options, letting instance args win" do
    klass = Class.new(Forms::Base) do
      form_options :spaced, url: "/signup"
      def fields = field(:email)
    end

    output = klass.new(model: user).call
    expect(output).to include('action="/signup"')
    expect(output).to include("space-y-4")

    expect(klass.new(model: user, url: "/override").call).to include('action="/override"')
  end

  it "merges form_options down the subclass chain" do
    parent = Class.new(Forms::Base) { form_options :spaced, url: "/parent" }
    child = Class.new(parent) do
      form_options url: "/child"
      def fields = field(:email)
    end

    output = child.new(model: user).call

    expect(output).to include('action="/child"')  # child default beats parent's
    expect(output).to include("space-y-4")        # parent modifier inherited
  end

  it "appends a render-time block after the declared fields" do
    output = form_class.new(model: user).call { |f| f.Hidden(:token) }

    expect(output).to include('name="user[token]"')
    expect(output.index("Create User")).to be < output.index('name="user[token]"')
  end
end
