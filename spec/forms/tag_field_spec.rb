# frozen_string_literal: true

require "spec_helper"

# TagField composes phlex-reactive's client-only tag primitives (raw wire-contract
# data attributes — see issue #6 Caveat 1) into a polished, model-bound leaf.
# The file only autoloads when Phlex::Reactive is present (the Forms::Live gate),
# so guard the whole group.
if defined?(Phlex::Reactive)
  describe Forms::TagField do
    subject(:output) do
      render_component(described_class.new(
        name: "user[tags]", id: "user_tags", value:, suggestions:
      ))
    end

    let(:value) { %w[Ruby Rails] }
    let(:suggestions) { %w[Ruby Rails Hotwire Postgres] }

    describe "the submitted value" do
      it "renders a hidden field carrying the comma-joined tags under the field name" do
        expect(output).to include('type="hidden"')
        expect(output).to include('name="user[tags]"')
        expect(output).to match(/name="user\[tags\]"[^>]*value="Ruby,Rails"/)
      end

      it "joins an Array value with commas and coerces a String value as-is" do
        array = render_component(described_class.new(name: "t", id: "t", value: %w[a b]))
        string = render_component(described_class.new(name: "t", id: "t", value: "a,b"))

        expect(array).to match(/name="t"[^>]*value="a,b"/)
        expect(string).to match(/name="t"[^>]*value="a,b"/)
      end
    end

    describe "the wire contract (the 0.12.2 escape-hatch sugar)" do
      it "targets the hidden field by [name=...] on the root" do
        # instance-dynamic wire name via reactive_tags(name: @name) — the 0.12.2
        # escape hatch that the symbol sugar can't express (issue #6 Caveat 1);
        # validated at render (see the malformed-name example below).
        expect(output).to include(%(data-reactive-tags-field="[name=&quot;user[tags]&quot;]"))
      end

      it "emits both filter selectors so the client type-ahead actually runs" do
        # reactive_filter(input:) emits reactive-filter-input AND
        # reactive-filter-option; the 0.12.x client #syncFilter early-returns
        # unless BOTH are present, so the raw -input-only workaround left
        # filtering dead. This is the regression guard (issue #6 Caveats 1 & 2).
        expect(output).to include(%(data-reactive-filter-input="#user_tags_query"))
        expect(output).to include(%(data-reactive-filter-option="[role=option]"))
      end

      it "validates the wire name at render (reactive_tags name: escape hatch)" do
        # A wire name with a double quote would break the [name="…"] CSS selector
        # the client queries with; verbatim_name_selector! fails loudly at render
        # instead of silently mis-binding in the browser.
        expect do
          render_component(described_class.new(name: 'user[tags"]', id: "t", value: []))
        end.to raise_error(ArgumentError, /double quote/)
      end

      it "marks the reactive root, tags list, and chip template" do
        # Phlex emits valueless boolean data attributes (data-reactive-tags-list,
        # not =...="true"); the client keys on presence.
        expect(output).to include("data-controller=") # reactive_root controller
        expect(output).to include("data-reactive-tags-list")
        expect(output).to include("data-reactive-tags-template")
        expect(output).to include("<template")
      end
    end

    describe "server-rendered first paint" do
      it "renders one chip per current tag, each carrying its value and a remove control" do
        expect(output).to include('data-reactive-tag="Ruby"')
        expect(output).to include('data-reactive-tag="Rails"')
        expect(output).to include("data-reactive-tag-text") # valueless boolean attr
        # the remove button wires the client tagsRemove action + the per-chip tag
        # param (reactive_tags_remove helper, phlex-reactive 0.11.4 contract)
        expect(output).to include("click->reactive#tagsRemove")
        expect(output).to include('data-reactive-tag-param="Ruby"')
        expect(output).to include('data-reactive-tag-param="Rails"')
      end

      it "renders a chip <template> whose remove button omits the tag param (client fills per clone)" do
        template = output[%r{<template[^>]*>.*?</template>}m]
        expect(template).to include("data-reactive-tag-text")
        expect(template).to include("click->reactive#tagsRemove")
        # the prototype's remove button carries the action but NO resolved tag —
        # the client sets data-reactive-tag-param per cloned chip
        expect(template).not_to include("data-reactive-tag-param=")
      end
    end

    describe "the query input" do
      it "has NO name so it never submits a stray param (issue #6 Caveat 2)" do
        # The only name= attribute in the whole widget is the hidden field's — the
        # query input carries none, so it never posts a stray param. (A per-input
        # slice regex is unreliable: the Stimulus data-action value has literal
        # `->`, so [^>]* stops short; count the field-level attr instead.)
        expect(output).to include('type="search"')
        expect(output).to include('id="user_tags_query"')
        expect(output.scan(/\sname="/).size).to eq(1) # hidden field only
        expect(output).to include('name="user[tags]"')
      end

      it "targets the query input by id from the root filter attr (no [name] selector)" do
        expect(output).to include(%(data-reactive-filter-input="#user_tags_query"))
      end
    end

    describe "suggestions" do
      it "renders each suggestion as a role=option button wired to tagsPick with its tag param" do
        %w[Ruby Rails Hotwire Postgres].each do |tag|
          expect(output).to include(">#{tag}<")
        end
        # reactive_tags_option helper: role=option (so filter/listnav see it),
        # forced type=button (never submits), the tagsPick action + tag param
        expect(output).to include('role="option"')
        expect(output).to include("click->reactive#tagsPick")
        expect(output).to include('data-reactive-tag-param="Postgres"')
      end

      it "adds free text on Enter via the query input (tagsAdd mixed after listnav)" do
        expect(output).to include("keydown.enter->reactive#tagsAdd")
      end

      context "when suggestions is a Hash of tag => haystack (synonyms the filter matches)" do
        let(:suggestions) { { "Postgres" => "postgres database db sql" } }

        it "carries the haystack as the filter text on each option" do
          expect(output).to include(%(data-reactive-filter-text="postgres database db sql"))
        end
      end
    end

    describe "error state" do
      it "flags the query input with aria-invalid when the field is invalid" do
        invalid = render_component(described_class.new(
          name: "t", id: "t", value: [], suggestions: [], error: true
        ))

        # Phlex serializes a boolean-true attribute valueless; the codebase
        # convention (theme_spec, the Plain twins) asserts on presence. The
        # aria-invalid rides the only search input in the widget.
        expect(invalid).to include('type="search"')
        expect(invalid).to include("aria-invalid")
      end
    end
  end
end
