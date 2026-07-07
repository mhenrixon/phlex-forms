# frozen_string_literal: true

# Entry point for phlex-forms' RuboCop cops. A host app enables them by adding
# to its .rubocop.yml:
#
#   require:
#     - phlex_forms/rubocop
#   inherit_gem:
#     phlex-forms: config/rubocop.yml
#
require "rubocop"

require_relative "../rubocop/phlex_forms/cop/raw_form"
require_relative "../rubocop/phlex_forms/cop/legacy_form_method"
