# frozen_string_literal: true

module Forms
  module Live
    # A Forms::Field that merges the blur-time validate trigger into every
    # input's data attributes (via apply_validations, the seam every builder
    # already routes options through).
    class Field < Forms::Field
      def initialize(live_trigger: nil, **)
        super(**)
        @live_trigger = live_trigger
      end

      def apply_validations(options)
        merged = super
        return merged unless @live_trigger

        merged.merge(data: merge_data(merged[:data], @live_trigger[:data]))
      end
    end
  end
end
