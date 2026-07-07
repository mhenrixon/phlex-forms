# frozen_string_literal: true

module PhlexForms
  # Class-string merging for phlex-forms components.
  #
  # DaisyUI component-class families are mutually exclusive: an element can't be
  # both `input-sm` and `input-lg`, or both `input-primary` and `input-error`.
  # When a component's default classes and a caller's `class:` override both name
  # the same family, the LAST occurrence wins — matching Tailwind/daisyui
  # intuition (the later class overrides the earlier).
  #
  # We deliberately do NOT depend on tailwind_merge: on form fields, callers pass
  # daisyui modifiers (which this handles) rather than conflicting core Tailwind
  # utilities, so tailwind_merge would add a runtime dependency for a conflict
  # that does not occur here. Non-conflicting utilities (`w-full`, `py-0`, ...)
  # simply pass through in order.
  module ClassMerge
    SIZE = /-(xs|sm|md|lg|xl)\z/
    COLOR = /-(primary|secondary|accent|neutral|info|success|warning|error)\z/

    module_function

    # Merge any number of class strings/nil into one deduped string. Preserves
    # order; within a daisyui size/color family only the last token survives.
    def merge(*parts)
      tokens = parts.flat_map { |p| p.to_s.split }.reject(&:empty?)
      dedupe_daisyui_families(tokens).join(" ")
    end

    # For each (component-prefix, family) pair, keep only the last token.
    def dedupe_daisyui_families(tokens)
      last_index = {}
      tokens.each_with_index do |tok, idx|
        key = family_key(tok)
        last_index[key] = idx if key
      end
      tokens.each_with_index.filter_map do |tok, idx|
        key = family_key(tok)
        next tok if key.nil? # not a daisyui family token — keep
        next tok if last_index[key] == idx # last in its family — keep

        nil # earlier duplicate in the family — drop
      end
    end

    # A stable bucket key like "input:size" / "select:color", or nil if the token
    # is not a recognized daisyui size/color modifier.
    def family_key(token)
      if (m = token.match(SIZE))
        "#{token[0...m.begin(0)]}:size"
      elsif (m = token.match(COLOR))
        "#{token[0...m.begin(0)]}:color"
      end
    end
  end
end
