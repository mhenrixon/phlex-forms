# frozen_string_literal: true

# In-memory registry of the reference docs. One line per page — slug and view
# derive from the title (both overridable), and the sidebar nav derives from this
# registry with zero extra code (see config/initializers/docs_kit.rb's
# `nav_registries`). It also feeds the AI surfaces (/llms.txt, /llms-full.txt,
# search, MCP): an unwritten page (whose view class doesn't resolve yet) is
# silently skipped everywhere, so the whole list can be declared up front as a
# burn-down of pages to author.
#
# Add a page with `rails g docs_kit:page "Title" --group=…`, which appends the
# `page` line here and writes the class under app/views/docs/pages/. Uses
# DocsKit::Registry for the shared all/from_slug/grouped/nav_items API.
class Doc
  extend DocsKit::Registry
  path_prefix    "/docs"
  view_namespace "Views::Docs::Pages"

  # Getting started
  page "Overview",     group: "Getting started"
  page "Installation", group: "Getting started"
  page "Quick start",  group: "Getting started", slug: "quick-start", view: "QuickStart"

  # Guide
  page "The field API",   group: "Guide", slug: "field-api", view: "FieldApi"
  page "Type inference",  group: "Guide", slug: "inference", view: "Inference"
  page "Form classes",    group: "Guide", slug: "form-classes", view: "FormClasses"
  page "Layout",          group: "Guide"
  page "Variants",        group: "Guide"
  page "Theming",         group: "Guide"

  # Validation
  page "Live validation",        group: "Validation", slug: "live-validation", view: "LiveValidation"
  page "Client-side validation", group: "Validation", slug: "client-validation", view: "ClientValidation"

  # Reference
  page "Nested & collections",   group: "Reference", slug: "nested-collections", view: "NestedCollections"
  page "Escape hatches",         group: "Reference", slug: "escape-hatches", view: "EscapeHatches"
  page "Configuration",          group: "Reference"
  page "RuboCop cops",           group: "Reference", slug: "rubocop-cops", view: "RubocopCops"
end
