# phlex-forms docs

The documentation site for [phlex-forms](https://github.com/mhenrixon/phlex-forms),
built on [docs-kit](https://docs-kit.zoolutions.llc) and served at
<https://phlex-forms.zoolutions.llc>.

## Develop

```shell
bundle install
bun install
bin/dev            # Puma + tailwind watch (Procfile.dev)
```

Pages live in `app/views/docs/pages/` and register in `app/models/doc.rb`
(`rails g docs_kit:page "Title" --group=…` scaffolds both). The site serves
`/llms.txt`, per-page `.md` twins, search, and a read-only MCP endpoint at
`POST /mcp`.

## Deploy

`bin/deploy` (Kamal) or the `Deploy docs` GitHub workflow (runs on release).
Regenerate the social cards with `bin/rails docs_kit:og` after landing changes.
