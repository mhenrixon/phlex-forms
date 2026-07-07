# frozen_string_literal: true

require "spec_helper"

describe "Forms components" do
  def render_form(model, **args, &block)
    render_form_via(model, **args, &block)
  end

  # Reuse the PhlexHelpers form renderer.
  def render_form_via(model, **args, &block)
    PhlexHelpers::FormContext.new(model:, form_args: args, form_block: block).call
  end

  describe "delegated leaf variants" do
    let(:user) { build_model(:user, name: "Ada") }

    it "stacks positional daisyui modifiers on the input" do
      output = render_form(user) { |f| f.field(:name, :primary, :lg) }
      expect(output).to include('class="input input-primary input-lg w-full"')
    end

    it "treats v4 :bordered as a no-op (v5 has the border on the base class)" do
      output = render_form(user) { |f| f.field(:name, :bordered, :primary) }
      expect(output).not_to include("input-bordered")
      expect(output).to include("input-primary")
    end
  end

  describe "fields_for (has_many nested attributes)" do
    it "renders indexed nested attribute names" do
      child = Class.new do
        include ActiveModel::Model

        def self.name = "LineItem"
        attr_accessor :description
      end
      parent = build_model(:invoice, line_items: [child.new(description: "A"), child.new(description: "B")])

      output = render_form(parent) do |f|
        f.fields_for(:line_items) { |lf| lf.field(:description) }
      end

      expect(output).to include('name="invoice[line_items_attributes][0][description]"')
      expect(output).to include('name="invoice[line_items_attributes][1][description]"')
    end
  end

  describe "collection_check_boxes" do
    it "emits the empty-array hidden field and a checkbox per item" do
      item = Struct.new(:id, :label)
      collection = [item.new(1, "One"), item.new(2, "Two")]
      user = build_model(:user, role_ids: [1])

      output = render_form(user) do |f|
        f.collection_check_boxes(:role_ids, collection, :id, :label) do |b|
          f.render(b.check_box)
          f.render(b.label)
        end
      end

      expect(output).to include('<input type="hidden" name="user[role_ids][]" value="">')
      expect(output).to include('name="user[role_ids][]"')
      expect(output).to include("One")
      expect(output).to include("Two")
    end
  end

  describe "client-side validation wiring" do
    let(:partner) do
      build_model(:partner, title: nil, slug: nil,
        validations: -> { validates :title, presence: true, length: { maximum: 60 } })
    end

    it "attaches the coordinator + novalidate when validate: true" do
      output = render_form(partner, validate: true, &:submit)
      expect(output).to include("novalidate")
      expect(output).to include("forms--validations--form")
    end

    it "wires per-field validator controllers from the model" do
      output = render_form(partner, validate: true) { |f| f.field(:title) }
      expect(output).to include("forms--validations--presence forms--validations--length")
      expect(output).to include('data-forms--validations--length-maximum-value="60"')
    end

    it "opts a field out with validate: false" do
      output = render_form(partner, validate: true) { |f| f.field(:title, validate: false) }
      expect(output).not_to include("forms--validations--presence")
    end
  end
end
