# frozen_string_literal: true

require "spec_helper"

describe Forms::Validations::Introspector do
  def model_class(&validations)
    Class.new do
      include ActiveModel::Model

      def self.name = "Widget"
      attr_accessor :title, :count, :kind, :terms, :password, :password_confirmation

      class_exec(&validations)
    end
  end

  def data_for(attribute, &validations)
    described_class.for(model_class(&validations)).data_attributes_for(attribute)
  end

  it "returns {} for an attribute with no supported validators" do
    data = data_for(:title) { validate :title, &:present? }
    expect(data).to eq({})
  end

  it "emits the presence controller and required value" do
    data = data_for(:title) { validates :title, presence: true }
    expect(data[:controller]).to eq("validations--presence")
    expect(data[:validations__presence_required_value]).to eq("true")
  end

  it "emits length min/max values" do
    data = data_for(:title) { validates :title, length: { minimum: 3, maximum: 60 } }
    expect(data[:validations__length_minimum_value]).to eq("3")
    expect(data[:validations__length_maximum_value]).to eq("60")
  end

  it "consolidates multiple validators into one space-joined controller list" do
    data = data_for(:title) { validates :title, presence: true, length: { maximum: 60 } }
    expect(data[:controller]).to eq("validations--presence validations--length")
  end

  it "converts a Ruby regex to a JS-compatible pattern (\\A/\\z -> ^/$)" do
    data = data_for(:title) { validates :title, format: { with: /\A[a-z]+\z/i } }
    expect(data[:validations__format_pattern_value]).to eq("^[a-z]+$")
    expect(data[:validations__format_flags_value]).to eq("i")
  end

  it "emits numericality bounds" do
    data = data_for(:count) { validates :count, numericality: { greater_than_or_equal_to: 0, only_integer: true } }
    expect(data[:validations__numericality_greater_than_or_equal_to_value]).to eq("0")
    expect(data[:validations__numericality_only_integer_value]).to eq("true")
  end

  it "emits inclusion list as JSON" do
    data = data_for(:kind) { validates :kind, inclusion: { in: %w[a b c] } }
    expect(data[:validations__inclusion_in_value]).to eq('["a","b","c"]')
  end

  it "emits the confirmation match attribute" do
    data = data_for(:password) { validates :password, confirmation: true }
    expect(data[:validations__confirmation_match_value]).to eq("password_confirmation")
  end

  it "skips validators with :if / :unless / :on (need server context)" do
    data = data_for(:title) { validates :title, presence: true, if: -> { true } }
    expect(data).to eq({})
  end

  it "returns a Null introspector for nil models" do
    expect(described_class.for(nil).data_attributes_for(:anything)).to eq({})
  end

  describe "paired with ManualRules" do
    it "produces the same data shape from an inline rules hash" do
      data = Forms::Validations::ManualRules.new(length: { maximum: 30 }, presence: true).data_attributes
      expect(data[:controller]).to include("validations--length")
      expect(data[:controller]).to include("validations--presence")
      expect(data[:validations__length_maximum_value]).to eq("30")
    end
  end
end
