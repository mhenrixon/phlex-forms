# frozen_string_literal: true

# row and group: side-by-side fields and fieldset sections.
class Views::Docs::Pages::Layout < DocsUI::Page
  title "Layout"
  eyebrow "Guide"

  def lead = "Two helpers cover most form layout: row for side-by-side fields, group for fieldset sections."

  def content
    rows
    groups
    everywhere
  end

  private

  def rows
    DocsUI::Section("Rows") do
      md <<~'MD'
        `row` wraps its fields in a responsive grid — stacked on mobile,
        `columns:` across from the `sm` breakpoint (2, 3, or 4):
      MD
      DocsUI::Code(<<~'RUBY')
        row do
          field :first_name
          field :last_name
        end

        row(columns: 3, class: "mt-2") do
          field :city
          field :zip
          field :country
        end
      RUBY
      md <<~'MD'
        The grid classes are literal strings, so a host app's Tailwind scanner
        picks them up from the gem source. A caller `class:` merges on top.
      MD
    end
  end

  def groups
    DocsUI::Section("Groups") do
      md <<~'MD'
        `group` renders a daisyUI fieldset with an optional legend — semantic
        sectioning for related fields:
      MD
      DocsUI::Code(<<~'RUBY')
        group(legend: "Address") do
          field :street
          row { field :city; field :zip }
        end
      RUBY
      DocsUI::Callout(:note) do
        plain "It's named "
        code { "group" }
        plain " (not "
        code { "section" }
        plain " or "
        code { "fieldset" }
        plain ") because those are Phlex::HTML element methods — defining them "
        plain "would shadow the elements inside every form."
      end
    end
  end

  def everywhere
    DocsUI::Section("Available everywhere") do
      md <<~'MD'
        Both helpers work on the inline builder (`f.row { … }`), as bare calls
        inside a `Forms::Base` class, and inside `fields_for` builders. Under
        the [Plain theme](/docs/theming) they degrade to an unstyled `div`
        (with a `data-form-row` hook) and a bare `fieldset`/`legend`.
      MD
    end
  end
end
