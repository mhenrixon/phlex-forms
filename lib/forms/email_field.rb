# frozen_string_literal: true

module Forms
  # Convenience: an Input pre-typed as email with a sensible default placeholder.
  #   EmailField(:primary, name: "user[email]")
  class EmailField < Input
    def initialize(*, placeholder: "email@example.com", **)
      super(*, type: "email", placeholder:, **)
    end
  end
end
