# frozen_string_literal: true

require "spec_helper"
require "action_view"

describe Forms::TimeZoneSelect do
  # Give the component the phlex-rails TimeZoneOptionsForSelect helper the way a
  # Rails host does. The helper delegates to ActionView, so include its module.
  before do
    skip "phlex-rails TimeZoneOptionsForSelect not loaded" unless
      defined?(Phlex::Rails::Helpers::TimeZoneOptionsForSelect)
  end

  it "renders a <select> populated with time-zone options, with the selected one marked" do
    output = render(described_class.new(name: "user[time_zone]", id: "user_time_zone", selected: "UTC"))

    expect(output).to include("<select")
    expect(output).to include('name="user[time_zone]"')
    expect(output).to include("UTC")
    # the options come from time_zone_options_for_select (built on self, not the
    # yielded DaisyUI::Select) and are emitted as safe HTML, not raised on.
    expect(output).to match(/<option[^>]*selected[^>]*>[^<]*UTC/)
  end
end
