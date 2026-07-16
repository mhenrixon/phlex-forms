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
  # Width utilities (`w-*`) are the one core-Tailwind family this gem injects a
  # default for (DelegatedField's `w-full`), so they conflict the same way: a
  # caller's `w-36` must REPLACE the default, or both land on the element and
  # stylesheet source order — not author intent — decides which applies.
  #
  # We deliberately do NOT depend on tailwind_merge: daisyui modifier families
  # and the width family are the only conflicts that occur on form fields, so
  # tailwind_merge would add a runtime dependency for conflicts this handles.
  # Other non-conflicting utilities (`py-0`, `min-w-32`, ...) pass through in
  # order.
  module ClassMerge
    SIZE = /-(xs|sm|md|lg|xl)\z/
    COLOR = /-(primary|secondary|accent|neutral|info|success|warning|error)\z/
    # Anchored so min-w-*/max-w-* (different CSS properties) stay out of the family.
    WIDTH = /\Aw-/

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

    # A stable bucket key like "width" / "input:size" / "select:color", or nil if
    # the token is not a recognized conflicting family. WIDTH is checked first so
    # a `w-*` token can never be mis-bucketed as a daisyui modifier.
    def family_key(token)
      return "width" if WIDTH.match?(token)

      if (m = token.match(SIZE))
        "#{token[0...m.begin(0)]}:size"
      elsif (m = token.match(COLOR))
        "#{token[0...m.begin(0)]}:color"
      end
    end
  end
end
