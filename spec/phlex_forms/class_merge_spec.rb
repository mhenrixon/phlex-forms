# frozen_string_literal: true

require "spec_helper"

describe PhlexForms::ClassMerge do
  describe ".merge" do
    it "keeps a single set of base classes untouched" do
      expect(described_class.merge("input input-bordered w-full")).to eq("input input-bordered w-full")
    end

    it "resolves conflicting daisyui sizes with last-one-wins" do
      expect(described_class.merge("input input-sm", "input-lg")).to eq("input input-lg")
    end

    it "resolves conflicting daisyui colors with last-one-wins" do
      expect(described_class.merge("input input-primary", "input-error")).to eq("input input-error")
    end

    it "keeps size and color from the same component (different families)" do
      result = described_class.merge("input input-primary input-sm")
      expect(result).to eq("input input-primary input-sm")
    end

    it "does not cross component boundaries when deduping" do
      # input-sm and select-sm are different components; both survive.
      result = described_class.merge("input-sm select-sm")
      expect(result.split).to contain_exactly("input-sm", "select-sm")
    end

    it "lets a caller override a component default size" do
      # Component default is input-md; caller passes input-lg last.
      expect(described_class.merge("input input-md", "input-lg")).to eq("input input-lg")
    end

    it "hands arbitrary tailwind utility conflicts to tailwind_merge" do
      expect(described_class.merge("w-full", "w-1/2")).to eq("w-1/2")
    end

    it "ignores nil and empty parts" do
      expect(described_class.merge("input", nil, "", "input-bordered")).to eq("input input-bordered")
    end
  end
end
