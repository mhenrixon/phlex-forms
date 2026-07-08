# frozen_string_literal: true

require "spec_helper"

# End-to-end: `f.field :tags, as: :tags, suggestions: [...]` renders the polished
# tag widget wrapped in the standard control chrome (label + error/hint), bound to
# the model, submitting one comma-joined param.
if defined?(Phlex::Reactive)
  describe "field :tags, as: :tags" do
    let(:model) do
      build_model(:post, tags: %w[Ruby Rails],
        validations: -> { attribute :tags })
    end

    it "renders the tag widget with the model's value, under the field's control chrome" do
      output = render_form(model) do |f|
        f.field :tags, as: :tags, suggestions: %w[Ruby Rails Hotwire]
      end

      # control chrome: the humanized label
      expect(output).to include("Tags")
      # the hidden field carries the comma-joined model value under the scoped name
      expect(output).to match(/name="post\[tags\]"[^>]*value="Ruby,Rails"/)
      # the wire contract targets that field
      expect(output).to include(%(data-reactive-tags-field="[name=&quot;post[tags]&quot;]"))
      # suggestions rendered
      expect(output).to include(">Hotwire<")
      # the query input never submits (only the hidden field carries name=)
      expect(output.scan(/\sname="post\[tags\]"/).size).to eq(1)
    end

    it "passes Hash suggestions (haystacks) through to the filter text" do
      output = render_form(model) do |f|
        f.field :tags, as: :tags, suggestions: { "Postgres" => "postgres database db" }
      end

      expect(output).to include(%(data-reactive-filter-text="postgres database db"))
    end

    it "renders under the plain theme with the wire contract intact and no daisy classes" do
      output = render_form(model, theme: :plain) do |f|
        f.field :tags, as: :tags, suggestions: %w[Ruby]
      end

      expect(output).to include("data-reactive-tags-field=")
      expect(output).to match(/name="post\[tags\]"[^>]*value="Ruby,Rails"/)
      expect(output).not_to include("badge")
    end

    it "surfaces a field error through the standard control chrome" do
      model.errors.add(:tags, "must include at least one tag")

      output = render_form(model) do |f|
        f.field :tags, as: :tags, suggestions: %w[Ruby]
      end

      expect(output).to include("must include at least one tag")
    end
  end
end
