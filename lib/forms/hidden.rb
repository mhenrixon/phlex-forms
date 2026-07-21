# frozen_string_literal: true

module Forms
  # A model-bound hidden field: a bare <input type="hidden"> carrying name/id/
  # value plus whatever the caller passes through. Deliberately NOT a
  # DelegatedField/DaisyUI::Input like Forms::Input — a hidden field must never
  # carry visual styling. daisyui's `.input { display: inline-flex }` overrides
  # WebKit's *non*-!important UA rule `input[type=hidden] { display: none }`, so a
  # styled hidden field renders as an empty box and joins the keyboard tab order
  # in Safari (Chromium's UA rule is !important, hiding the bug there).
  #
  #   Forms::Hidden.new(name: "user[token]", id: "user_token", value: "abc123")
  #
  # Same component under both themes (:hidden role) — there are no styling
  # classes for a Plain twin to strip. It takes no positional variants and no
  # error:: a hidden field has no visual or error state.
  class Hidden < Phlex::HTML
    def initialize(name: nil, id: nil, value: nil, **attributes)
      @name = name
      @id = id
      @value = value
      @attributes = attributes
      super()
    end

    def view_template
      input(type: "hidden", name: @name, id: @id, value: @value.to_s, **@attributes)
    end
  end
end
