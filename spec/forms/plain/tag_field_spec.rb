# frozen_string_literal: true

require "spec_helper"

# The Plain twin keeps the FULL client wire contract (the reactive tag behavior
# must still work under the plain theme) but ships zero daisyUI styling classes.
if defined?(Phlex::Reactive)
  describe Forms::Plain::TagField do
    subject(:output) do
      render_component(described_class.new(
        name: "user[tags]", id: "user_tags", value: %w[Ruby Rails],
        suggestions: { "Postgres" => "postgres db" }, error: true
      ))
    end

    it "keeps the reactive wire contract (behavior must still work under plain)" do
      expect(output).to include(%(data-reactive-tags-field="[name=&quot;user[tags]&quot;]"))
      expect(output).to include("data-reactive-filter-input=\"#user_tags_query\"")
      expect(output).to include("data-reactive-tags-list")
      expect(output).to include("data-reactive-tags-template")
      expect(output).to include("data-reactive-tag=\"Ruby\"")
      expect(output).to include("keydown.enter->reactive#tagsAdd")
      expect(output).to include("click->reactive#tagsPick")
      expect(output).to include("click->reactive#tagsRemove")
      expect(output).to include("data-reactive-tag-param=")
      expect(output).to include("data-reactive-filter-text=\"postgres db\"")
    end

    it "submits one comma-joined hidden field" do
      expect(output).to match(/name="user\[tags\]"[^>]*value="Ruby,Rails"/)
    end

    it "ships NO daisyUI styling classes (badge / menu / input)" do
      expect(output).not_to include("badge")
      expect(output).not_to include("menu")
      expect(output).not_to include('class="input')
    end

    it "flags the invalid field with aria-invalid on the query input, not a color class" do
      expect(output).to include("aria-invalid")
    end
  end
end
