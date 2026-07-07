# frozen_string_literal: true

module Forms
  # A daisyui fieldset with an optional legend, for sectioning related fields.
  # Exposed as `f.group` (not `section`/`fieldset` — those are Phlex::HTML
  # element methods and defining them would shadow the elements inside forms).
  #
  #   f.group(legend: "Address") { f.field :street; f.field :city }
  class Group < Phlex::HTML
    def initialize(legend: nil, **options)
      @legend = legend
      @options = options
      super()
    end

    def view_template
      render DaisyUI::Fieldset.new(**@options) do |fs|
        fs.legend { @legend } if @legend
        yield if block_given?
      end
    end
  end
end
