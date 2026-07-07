# frozen_string_literal: true

module Forms
  # Convenience: an Input pre-typed as password.
  #   PasswordField(:primary, name: "user[password]")
  class PasswordField < Input
    def initialize(*, placeholder: "••••••••", autocomplete: "current-password", **)
      super(*, type: "password", placeholder:, autocomplete:, **)
    end
  end
end
