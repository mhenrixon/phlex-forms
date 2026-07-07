# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require "phlex_forms/rubocop"

RSpec.describe RuboCop::Cop::PhlexForms::RawForm, :config do
  include RuboCop::RSpec::ExpectOffense

  it "flags form_with and autocorrects to Form" do
    expect_offense(<<~RUBY)
      form_with(model: @user) { |f| f.field(:email) }
      ^^^^^^^^^ Use `Form(model: @model)` instead of `form_with`.
    RUBY

    expect_correction(<<~RUBY)
      Form(model: @user) { |f| f.field(:email) }
    RUBY
  end

  it "flags a raw form() element with a block" do
    expect_offense(<<~RUBY)
      form(method: "post") { input }
      ^^^^ Use `Form()` instead of raw `form()`.
    RUBY
  end

  it "ignores a bare form reference with no args or block" do
    expect_no_offenses("form.label(:email)")
  end
end

RSpec.describe RuboCop::Cop::PhlexForms::LegacyFormMethod, :config do
  include RuboCop::RSpec::ExpectOffense

  it "flags legacy text_field on a form receiver" do
    expect_offense(<<~RUBY)
      form.text_field(:name, :primary)
           ^^^^^^^^^^ Use `form.field(...)` (or `form.Input(:name, :text, :primary)`) instead of legacy `form.text_field`.
    RUBY
  end

  it "flags legacy select and points at field/Select" do
    expect_offense(<<~RUBY)
      f.select(:role, choices: roles)
        ^^^^^^ Use `form.field(...)` (or `form.Select(:role, choices: roles)`) instead of legacy `f.select`.
    RUBY
  end

  it "leaves the new API alone" do
    expect_no_offenses("form.field(:name, :primary)")
    expect_no_offenses("form.Input(:name, :primary)")
  end
end
