# frozen_string_literal: true

module PhlexForms
  # Class-string merging for phlex-forms components.
  #
  # Two problems, two mechanisms:
  #
  # 1. DaisyUI component-class conflicts (`input-sm` vs `input-lg`,
  #    `input-primary` vs `input-error`). tailwind_merge with default config does
  #    NOT resolve these — it only understands core Tailwind utilities. We dedupe
  #    them by FAMILY with last-one-wins: for each recognized daisyui family
  #    (size, color, style), only the last occurrence survives.
  #
  # 2. Arbitrary Tailwind utility conflicts coming from a caller's `class:`
  #    override (`w-full` vs `w-1/2`, `p-2` vs `p-4`). Those we hand to
  #    tailwind_merge.
  #
  # The public `merge` runs family-dedup first, then tailwind_merge, so a caller
  # can always override a component default by passing the competing class.
  module ClassMerge
    # DaisyUI modifier families whose members are mutually exclusive. Keyed by a
    # regexp that captures the component+family; last match in the string wins.
    # `%s` is the component prefix (e.g. "input", "select", "btn").
    SIZE = /-(xs|sm|md|lg|xl)\z/
    COLOR = /-(primary|secondary|accent|neutral|info|success|warning|error)\z/

    module_function

    def merger
      @merger ||= TailwindMerge::Merger.new
    end

    # Merge any number of class strings/nil into one deduped string.
    def merge(*parts)
      tokens = parts.flat_map { |p| p.to_s.split }.reject(&:empty?)
      tokens = dedupe_daisyui_families(tokens)
      merger.merge(tokens.join(" "))
    end

    # For each (component-prefix, family) pair, keep only the last token.
    def dedupe_daisyui_families(tokens)
      seen_last = {}
      # First pass: record the index of the last token in each family bucket.
      tokens.each_with_index do |tok, idx|
        key = family_key(tok)
        seen_last[key] = idx if key
      end
      tokens.each_with_index.filter_map do |tok, idx|
        key = family_key(tok)
        next tok if key.nil? # not a daisyui family token — keep
        next tok if seen_last[key] == idx # last in its family — keep

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
