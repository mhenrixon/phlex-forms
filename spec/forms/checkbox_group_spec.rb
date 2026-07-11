# frozen_string_literal: true

require "spec_helper"

# Issue #9: a batched checkbox-group verb for array-valued associations. Renders
# a set of checkboxes sharing one array-valued field name and derives the checked
# set from the model's current value, matched by the resolved value: of each item.
describe "checkbox_group (issue #9)" do
  let(:tag) { Struct.new(:id, :name, :slug) }
  let(:collection) do
    [tag.new(1, "Ruby", "ruby"), tag.new(2, "Rails", "rails"), tag.new(3, nil, "hotwire")]
  end
  let(:user) { build_model(:user, tag_ids: [1, 3]) }

  describe "the builder verb" do
    it "shares one array-valued field name across every checkbox" do
      output = render_form(user) do |f|
        f.checkbox_group(:tag_ids, collection, value: :id, label: :name)
      end

      # 3 checkboxes + 1 empty-array hidden field all share the array name.
      checkboxes = output.scan(/type="checkbox"[^>]*name="user\[tag_ids\]\[\]"/)
      expect(checkboxes.size).to eq(3)
      expect(output.scan('name="user[tag_ids][]"').size).to eq(4)
    end

    it "emits a leading empty-array hidden field so an empty selection still submits" do
      output = render_form(user) do |f|
        f.checkbox_group(:tag_ids, collection, value: :id, label: :name)
      end

      expect(output).to include('<input type="hidden" name="user[tag_ids][]" value="">')
    end

    it "checks exactly the boxes whose value is in the model's current set" do
      output = render_form(user) do |f|
        f.checkbox_group(:tag_ids, collection, value: :id, label: :name)
      end

      # tag_ids == [1, 3] -> value 1 and 3 checked, value 2 not.
      expect(output).to match(/value="1"[^>]*checked/)
      expect(output).not_to match(/value="2"[^>]*checked/)
      expect(output).to match(/value="3"[^>]*checked/)
    end

    it "derives each option id from the field id and the value" do
      output = render_form(user) do |f|
        f.checkbox_group(:tag_ids, collection, value: :id, label: :name)
      end

      expect(output).to include('id="user_tag_ids_1"')
      expect(output).to include('id="user_tag_ids_2"')
    end

    it "resolves label: as a proc (with a fallback to the slug when name is blank)" do
      output = render_form(user) do |f|
        f.checkbox_group(
          :tag_ids, collection, value: :id,
          label: ->(t) { t.name || t.slug }
        )
      end

      expect(output).to include("Ruby")
      expect(output).to include("hotwire") # third item's name is nil -> slug
    end

    it "escapes option labels (no raw HTML injection)" do
      evil = [tag.new(1, "<script>", "x")]
      output = render_form(user) do |f|
        f.checkbox_group(:tag_ids, evil, value: :id, label: :name)
      end

      expect(output).not_to include("<script>")
      expect(output).to include("&lt;script&gt;")
    end

    it "maps size: to the daisyUI checkbox size class" do
      output = render_form(user) do |f|
        f.checkbox_group(:tag_ids, collection, value: :id, label: :name, size: :sm)
      end

      expect(output).to include("checkbox-sm")
    end
  end

  describe "field inference (as: :checkbox_group)" do
    it "dispatches through f.field with an explicit collection" do
      output = render_form(user) do |f|
        f.field(:tag_ids, as: :checkbox_group, collection:, value: :id, label: :name)
      end

      expect(output.scan(/type="checkbox"[^>]*name="user\[tag_ids\]\[\]"/).size).to eq(3)
      expect(output).to match(/value="1"[^>]*checked/)
    end
  end

  describe "theme parity" do
    it "renders under the plain theme with binding intact and zero styling classes" do
      output = render_form(user, theme: :plain) do |f|
        f.checkbox_group(:tag_ids, collection, value: :id, label: :name)
      end

      expect(output).to include('<input type="hidden" name="user[tag_ids][]" value="">')
      expect(output.scan(/type="checkbox"[^>]*name="user\[tag_ids\]\[\]"/).size).to eq(3)
      expect(output).to match(/value="1"[^>]*checked/)
      expect(output).not_to include("checkbox-")
    end

    it "maps the :checkbox_group role in both themes" do
      expect(PhlexForms::Theme.daisy[:checkbox_group]).to eq(Forms::CheckboxGroup)
      expect(PhlexForms::Theme.plain[:checkbox_group]).to eq(Forms::Plain::CheckboxGroup)
    end
  end
end
