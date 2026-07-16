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

    it "passes non-conflicting utilities through in order" do
      # No tailwind_merge dependency: additive utilities are simply preserved.
      expect(described_class.merge("input w-full", "py-0")).to eq("input w-full py-0")
    end

    it "ignores nil and empty parts" do
      expect(described_class.merge("input", nil, "", "input-bordered")).to eq("input input-bordered")
    end

    describe "width family (w-*)" do
      it "lets a caller width override the w-full default" do
        expect(described_class.merge("w-full", "w-36")).to eq("w-36")
      end

      it "keeps non-width tokens around the winning width" do
        expect(described_class.merge("w-full", "w-20 text-center")).to eq("w-20 text-center")
      end

      it "does not treat min-w-*/max-w-* as widths" do
        expect(described_class.merge("w-full", "min-w-32")).to eq("w-full min-w-32")
        expect(described_class.merge("w-full", "max-w-xs")).to eq("w-full max-w-xs")
      end

      it "keeps the default when the caller passes no width" do
        expect(described_class.merge("w-full", nil)).to eq("w-full")
      end

      it "handles arbitrary-value widths" do
        expect(described_class.merge("w-full", "w-[42px]")).to eq("w-[42px]")
      end
    end
  end
end
