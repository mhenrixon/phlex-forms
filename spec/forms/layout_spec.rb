# frozen_string_literal: true

require "spec_helper"

describe "layout helpers (row/group)" do
  let(:user) { build_model(:user, email: "a@b.c", first_name: nil, last_name: nil) }

  it "renders row as a responsive grid around fields" do
    output = render_form(user) do |f|
      f.row do
        f.field(:first_name)
        f.field(:last_name)
      end
    end

    expect(output).to include("grid grid-cols-1 gap-4 sm:grid-cols-2")
    expect(output).to include('name="user[first_name]"')
    expect(output).to include('name="user[last_name]"')
  end

  it "supports columns: and merges custom classes" do
    output = render_form(user) { |f| f.row(columns: 3, class: "mt-2") { f.field(:email) } }

    expect(output).to include("sm:grid-cols-3")
    expect(output).to include("mt-2")
  end

  it "renders group as a daisyui fieldset with a legend" do
    output = render_form(user) do |f|
      f.group(legend: "Contact") { f.field(:email) }
    end

    expect(output).to match(/<fieldset[^>]*class="fieldset"/)
    expect(output).to match(%r{<legend[^>]*class="fieldset-legend"[^>]*>Contact</legend>})
    expect(output).to include('name="user[email]"')
  end

  it "works through a fields_for builder (non-Phlex host)" do
    settings = build_model(:settings, locale: "en")

    output = render_form(user) do |f|
      f.fields_for(:settings, settings) do |s|
        s.row { s.field(:locale) }
      end
    end

    expect(output).to include("grid grid-cols-1 gap-4")
    expect(output).to include('name="user[settings_attributes][locale]"')
  end
end
