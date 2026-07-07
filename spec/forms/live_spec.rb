# frozen_string_literal: true

require "spec_helper"

describe Forms::Live do
  let(:model_class) do
    stub_const("LiveUser", Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :email
      attribute :password
      attribute :password_confirmation

      validates :email, presence: true
      validates :password, confirmation: true
    end)
  end

  let(:form_class) do
    klass = stub_const("LiveUserForm", Class.new(Forms::Base) do
      def fields
        field :email
        field :password
        field :password_confirmation
        submit :primary
      end
    end)
    klass.live(model: model_class)
    klass
  end

  describe "rendering" do
    it "makes the <form> the reactive root with a debounced whole-form input trigger" do
      output = form_class.new(model: model_class.new).call

      # each of these attribute strings appears only on the root <form>
      # (inputs bind blur, not input; only the root carries the token/id)
      expect(output).to include('id="new_live_user"')
      expect(output).to include('data-controller="reactive"')
      expect(output).to include("data-reactive-token-value=")
      expect(output).to include('data-action="input->reactive#dispatch"')
      expect(output).to include('data-reactive-action-param="validate"')
      expect(output).to include('data-reactive-debounce-param="300"')
    end

    it "wires each input with a blur trigger carrying its _touch param" do
      output = form_class.new(model: model_class.new).call

      expect(output).to include("blur->reactive#dispatch")
      expect(output).to match(/_touch.{0,20}email/)
      expect(output).to match(/_touch.{0,20}password_confirmation/)
    end
  end

  describe "#validate (the reactive action)" do
    # reply.morph renders through the request-bound view context, which only
    # exists inside a host app — stub the reply and assert the action's real
    # work: assignment, validation, touch tracking.
    def stub_reply(form)
      allow(form).to receive(:reply).and_return(instance_double(Phlex::Reactive::Reply, morph: :morphed))
    end

    it "assigns whitelisted fields, runs the real validators, and tracks the touch" do
      form = form_class.new(model: model_class.new)
      stub_reply(form)

      result = form.validate(
        _touch: "email",
        live_user: { "email" => "", "password" => "secret", "password_confirmation" => "different" }
      )

      expect(result).to eq(:morphed)
      expect(form.model.errors[:email]).to include("can't be blank")
      expect(form.model.errors[:password_confirmation]).to be_present
      expect(form.model.password).to eq("secret")
    end

    it "ignores attributes outside the whitelist and respects live_deny" do
      form_class.live_deny(:password)
      form = form_class.new(model: model_class.new)
      stub_reply(form)

      form.validate(live_user: { "password" => "sneaky", "not_an_attribute" => "x" })

      expect(form.model.password).to be_nil
    end
  end

  describe "touched-based error display" do
    it "hides errors on untouched fields and shows them once touched" do
      model = model_class.new
      untouched = form_class.new(model:)
      touched = form_class.new(model:, touched: ["email"])
      model.errors.add(:email, "is invalid")

      expect(untouched.call).not_to include("Email is invalid")
      expect(touched.call).to include("Email is invalid")
    end

    it "shows all errors on a form rendered after a failed submit (classic 422)" do
      model = model_class.new
      model.errors.add(:email, "is invalid")

      output = form_class.new(model:).call

      expect(output).to include("Email is invalid")
    end
  end

  describe "identity round trip" do
    it "rebuilds a new-record form from signed state (nil gid)" do
      rebuilt = form_class.from_identity(
        "c" => "LiveUserForm", "s" => { "model_gid" => nil, "touched" => ["email"] }
      )

      expect(rebuilt.model).to be_a(model_class)
      expect(rebuilt.model.persisted?).to be(false)
      expect(rebuilt.call).to include('id="new_live_user"')
    end
  end

  describe "guard rails" do
    it "raises on inline Form(live: true) pointing at Forms::Base" do
      expect { render_form(model_class.new, live: true) { |f| f.field(:email) } }
        .to raise_error(ArgumentError, /Forms::Base subclass/)
    end

    it "raises FeatureUnavailable from the live macro when phlex-reactive is absent" do
      klass = Class.new(Forms::Base)
      allow(klass).to receive(:reactive_available?).and_return(false)

      expect { klass.live(model: model_class) }
        .to raise_error(PhlexForms::FeatureUnavailable, /phlex-reactive/)
    end

    it "registers the :form_attributes param type idempotently" do
      expect { 2.times { described_class.register_param_type! } }.not_to raise_error
    end
  end
end
