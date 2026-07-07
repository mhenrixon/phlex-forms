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
        options = super
        return options unless @live_trigger

        options.merge(data: merge_data(options[:data], @live_trigger[:data]))
      end
    end
  end
end
