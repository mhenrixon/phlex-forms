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

  # Issue #17: role="group" needs an accessible name (and optional description)
  # so assistive tech announces the group's purpose when focus enters a checkbox.
  describe "accessible name (issue #17)" do
    describe "the bare verb" do
      # No bespoke naming API — HTML/ARIA attributes pass straight through to the
      # group div, so the caller names it with plain aria: {}.
      it "names the group via a passed-through aria: { label: }" do
        output = render_form(user) do |f|
          f.checkbox_group(:tag_ids, collection, value: :id, label: :name, aria: { label: "Tags" })
        end

        expect(output).to match(/role="group"[^>]*aria-label="Tags"/)
      end

      it "names the group via a passed-through aria: { labelledby: } id" do
        output = render_form(user) do |f|
          f.checkbox_group(:tag_ids, collection, value: :id, label: :name,
            aria: { labelledby: "external_heading", describedby: "external_hint" })
        end

        expect(output).to match(/role="group"[^>]*aria-labelledby="external_heading"/)
        expect(output).to include('aria-describedby="external_hint"')
      end

      it "passes arbitrary attributes (data:) through to the group" do
        output = render_form(user) do |f|
          f.checkbox_group(:tag_ids, collection, value: :id, label: :name,
            data: { controller: "chips" })
        end

        expect(output).to match(/role="group"[^>]*data-controller="chips"/)
      end

      it "escapes the attribute delimiter in a passed-through aria-label (no breakout)" do
        # Phlex escapes the quote delimiter (&quot;) so a value can't break out of
        # the attribute; < / > are inert inside a quoted attribute value, so the
        # <script> text stays trapped as an attribute value, never a new element.
        output = render_form(user) do |f|
          f.checkbox_group(:tag_ids, collection, value: :id, label: :name,
            aria: { label: '"><script>x' })
        end

        expect(output).to include('aria-label="&quot;><script>x"')
        # The dangerous form — an unescaped quote that closes the attribute and
        # opens a real <script> element — must NOT appear.
        expect(output).not_to include('aria-label=""><script>x')
      end

      it "emits only role + aria-invalid on the group when no aria given" do
        # Backward compatible with the #9 output (no accessible name is the
        # caller's responsibility — same posture as Rails' derived markup).
        output = render_form(user) do |f|
          f.checkbox_group(:tag_ids, collection, value: :id, label: :name)
        end

        expect(output).not_to include("aria-label")
        expect(output).not_to include("aria-labelledby")
        expect(output).not_to include("aria-describedby")
      end
    end

    describe "the f.field(as: :checkbox_group) path" do
      it "names the group via the Control's own label (no duplicate heading)" do
        output = render_form(user) do |f|
          f.field(:tag_ids, as: :checkbox_group, collection:, value: :id, label: "Tags")
        end

        # The Control's <label> carries a stable id...
        expect(output).to include('<label for="user_tag_ids" id="user_tag_ids_label">')
        expect(output).to include(">Tags</span>")
        # ...and the group points aria-labelledby at it.
        expect(output).to match(/role="group"[^>]*aria-labelledby="user_tag_ids_label"/)
        # Exactly one "Tags" text node — no duplicate heading inside the group.
        expect(output.scan(">Tags<").size).to eq(1)
      end

      it "describes the group via the Control's hint" do
        output = render_form(user) do |f|
          f.field(:tag_ids, as: :checkbox_group, collection:, value: :id,
            label: "Tags", hint: "Pick any")
        end

        expect(output).to match(/id="user_tag_ids_hint"[^>]*>Pick any/)
        expect(output).to match(/role="group"[^>]*aria-describedby="user_tag_ids_hint"/)
      end
    end

    describe "theme parity" do
      it "passes aria through under the plain theme with zero styling classes" do
        output = render_form(user, theme: :plain) do |f|
          f.checkbox_group(:tag_ids, collection, value: :id, label: :name,
            aria: { label: "Tags" })
        end

        expect(output).to match(/role="group"[^>]*aria-label="Tags"/)
        expect(output).not_to include('class="')
      end

      it "the plain f.field path stamps the Control's label/hint ids (no dangling aria)" do
        # The plain Control overrides view_template; it must thread label_id/hint_id
        # the same way, or the group's aria-* would point at ids that don't exist.
        output = render_form(user, theme: :plain) do |f|
          f.field(:tag_ids, as: :checkbox_group, collection:, value: :id,
            label: "Tags", hint: "Pick any")
        end

        expect(output).to include('id="user_tag_ids_label"')
        expect(output).to include('id="user_tag_ids_hint"')
        expect(output).to match(/role="group"[^>]*aria-labelledby="user_tag_ids_label"/)
        expect(output).to include('aria-describedby="user_tag_ids_hint"')
      end
    end
  end

  # Feedback follow-up: the f.field path took `label:` as the visible Control
  # heading, so the per-item label proc had nowhere to go (items fell back to
  # to_s). `item_label:` supplies the per-item text alongside a visible heading —
  # the marketplace tag-picker shape (heading + custom item labels) in one call.
  describe "item_label: (visible heading + custom item labels at once)" do
    it "renders the Control heading AND custom item labels via f.field" do
      output = render_form(user) do |f|
        f.field(:tag_ids, as: :checkbox_group, collection:, value: :id,
          label: "Tags", hint: "Pick any",
          item_label: ->(t) { t.name || t.slug })
      end

      # The visible Control heading (label:) is present and names the group.
      expect(output).to include(">Tags</span>")
      expect(output).to match(/role="group"[^>]*aria-labelledby="user_tag_ids_label"/)
      # Item labels come from the proc — the third item's name is nil -> its slug.
      expect(output).to include(">Ruby<")
      expect(output).to include(">hotwire<") # name nil -> slug fallback
      # NOT the struct's to_s (the pre-fix behavior).
      expect(output).not_to include("#<struct")
    end

    it "accepts item_label: as a Symbol method too" do
      output = render_form(user) do |f|
        f.field(:tag_ids, as: :checkbox_group, collection:, value: :id,
          label: "Tags", item_label: :slug)
      end

      expect(output).to include(">ruby<")
      expect(output).to include(">rails<")
    end

    it "on the bare verb, item_label: is an alias for the item accessor" do
      output = render_form(user) do |f|
        f.checkbox_group(:tag_ids, collection, value: :id,
          item_label: :slug, aria: { label: "Tags" })
      end

      expect(output).to include(">ruby<")
      expect(output).to include(">hotwire<")
    end

    it "item_label: wins over label: when both reach the group" do
      # label: :name would give nil for the third item; item_label: forces slug.
      output = render_form(user) do |f|
        f.checkbox_group(:tag_ids, collection, value: :id, label: :name, item_label: :slug)
      end

      expect(output).to include(">hotwire<") # slug, not the nil name
    end

    it "keeps an explicit label: accessor when item_label: is absent" do
      # Backward compatible with the bare-verb usage.
      output = render_form(user) do |f|
        f.checkbox_group(:tag_ids, collection, value: :id, label: :name)
      end

      expect(output).to include(">Ruby<")
      expect(output).to include(">Rails<")
    end

    it "infers item text (name/title/label/to_s) when neither label: nor item_label: given" do
      # The heading-only f.field case: label: is the Control heading, so nothing
      # reaches the group as an item accessor — it should still read the item's
      # name, not dump #<struct ...>.
      output = render_form(user) do |f|
        f.field(:tag_ids, as: :checkbox_group, collection:, value: :id, label: "Tags")
      end

      expect(output).to include(">Ruby<") # item.name, inferred
      expect(output).to include(">Rails<")
      expect(output).not_to include("#<struct")
    end

    it "treats a String item_label: as literal text (no method dispatch)" do
      # A plain object with no matching reader must not NoMethodError.
      plain = [Object.new, Object.new]
      output = render_form(build_model(:user, tag_ids: [])) do |f|
        f.checkbox_group(:tag_ids, plain, value: :object_id, item_label: "Pick me")
      end

      expect(output.scan(">Pick me<").size).to eq(2)
    end
  end
end
