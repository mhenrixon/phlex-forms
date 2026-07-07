# frozen_string_literal: true

# Normalizes rendered HTML so specs can compare against a readable heredoc
# without fighting whitespace. Mirrors the helper used in the daisyui gem.
module HTMLHelpers
  def html(string)
    string
      .gsub(/>\s+</, "><")
      .gsub(/(\S)\s*\n\s*(\S)/, '\1 \2')
      .gsub(/(\w+)="\s*(.+?)\s*"/) { |_m| "#{::Regexp.last_match(1)}=\"#{::Regexp.last_match(2).split.join(' ')}\"" }
      .gsub(/(\S+="[^"]*")\s*/, '\1 ')
      .gsub(/\s+>/, ">")
      .strip
  end
end
