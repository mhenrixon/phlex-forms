# frozen_string_literal: true

require "spec_helper"

# A tag field inside a Forms::Live form: declared with `live_tags`, its wire
# attributes are hoisted onto the <form> reactive root and the widget renders
# ROOTLESS, so the outer form OWNS the hidden tags field and live :validate sees
# the comma-joined value.
if defined?(Phlex::Reactive)
  describe "live_tags (tag field inside a live form)" do
    let(:model_class) do
      stub_const("TaggedPost", Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :title
        attribute :tags

        validates :title, presence: true
        validate { errors.add(:tags, "needs at least one tag") if Array(tags_list).empty? }

        # accept the widget's comma-joined string and a normal Array alike
        def tags=(value)
          super(value.is_a?(String) ? value.split(",").map(&:strip).reject(&:empty?) : value)
        end

        def tags_list = tags
      end)
    end

    let(:form_class) do
      klass = stub_const("TaggedPostForm", Class.new(Forms::Base) do
        def fields
          field :title
          field :tags, as: :tags
          submit :primary
        end
      end)
      klass.live(model: model_class)
      klass.live_tags(:tags, suggestions: %w[Ruby Rails Hotwire])
      klass
    end

    describe "rendering" do
      subject(:output) { form_class.new(model: model_class.new).call }

      it "hoists the tag wire attributes onto the <form> reactive root" do
        # The tag attrs ride on the <form> open tag, before any child element.
        # (A /<form[^>]*>/ slice is unusable: the Stimulus data-action value has
        # literal `->`, so [^>]* stops short — slice up to the first child tag.)
        form_tag = output[/\A.*?<(?:input|div|template)/m]
        expect(form_tag).to include("data-reactive-tags-field=")
        expect(form_tag).to include("tagged_post[tags]")
        expect(form_tag).to include("data-reactive-filter-input=")
        # Both filter selectors hoist (reactive_filter(input:), not the raw
        # -input-only attr) so the 0.12.x client type-ahead runs on the live
        # form root too (issue #6 Caveats 1 & 2).
        expect(form_tag).to include(%(data-reactive-filter-option="[role=option]"))
      end

      it "renders the tag widget ROOTLESS (no nested reactive root) so the form owns the hidden field" do
        # the ONLY data-controller=reactive is the <form> itself — the tag widget
        # does not open its own reactive root
        expect(output.scan(/data-controller="[^"]*reactive[^"]*"/).size).to eq(1)
        # the hidden tags field is present with the scoped name
        expect(output).to match(/type="hidden"[^>]*name="tagged_post\[tags\]"/)
        # the suggestion + chip behavior is still wired
        expect(output).to include("click->reactive#tagsPick")
        expect(output).to include("keydown.enter->reactive#tagsAdd")
      end
    end

    describe "#validate sees the tags value" do
      def stub_reply(form)
        allow(form).to receive(:reply).and_return(
          instance_double(Phlex::Reactive::Reply, morph: :morphed)
        )
      end

      it "assigns the comma-joined tags and runs the real validator over them" do
        form = form_class.new(model: model_class.new)
        stub_reply(form)

        form.validate(
          _touch: "tags",
          tagged_post: { "title" => "Hi", "tags" => "Ruby,Rails" }
        )

        expect(form.model.tags).to eq(%w[Ruby Rails])
        expect(form.model.errors[:tags]).to be_empty
      end

      it "surfaces the tags validator error when empty" do
        form = form_class.new(model: model_class.new)
        stub_reply(form)

        form.validate(_touch: "tags", tagged_post: { "title" => "Hi", "tags" => "" })

        expect(form.model.errors[:tags]).to include("needs at least one tag")
      end
    end

    describe "guard rails" do
      it "raises when a second tag field is declared live (one per reactive root)" do
        klass = Class.new(Forms::Base)
        klass.live(model: model_class)
        klass.live_tags(:tags, suggestions: [])

        expect { klass.live_tags(:categories, suggestions: []) }
          .to raise_error(ArgumentError, /at most one/)
      end
    end
  end
end
