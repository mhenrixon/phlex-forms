# frozen_string_literal: true

require_relative "lib/phlex_forms/version"

Gem::Specification.new do |s|
  s.name = "phlex-forms"
  s.version = Forms::VERSION
  s.licenses = ["MIT"]
  s.summary = "A model-bound, DaisyUI-styled form builder for Phlex"
  s.description = "phlex-forms gives Phlex apps a clean form builder: Form(model:) { |f| f.field :email } " \
                  "renders label + input + error/hint in one call, with type and required inferred from the model. " \
                  "Built on daisyui, it fixes what Rails and Phlex form builders get wrong about model binding, " \
                  "nested attributes, and DaisyUI styling."
  s.authors = ["Mikael Henriksson"]
  s.email = "mikael@zoolutions.llc"
  # Use `git ls-files` when packaging from a checkout; fall back to a Dir glob
  # when there is no .git. Both paths MUST ship the same prefixes — app/ and
  # config/ carry the Stimulus controllers (app/javascript) and importmap +
  # locale config, so omitting them would publish a broken gem.
  s.files = begin
    files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
      ls.readlines("\x0", chomp: true).select do |f|
        f.start_with?("exe/", "lib/", "app/", "config/") ||
          f == "CHANGELOG.md" || f == "LICENSE.txt" || f == "README.md"
      end
    end
    files.empty? ? raise(Errno::ENOENT) : files
  rescue Errno::ENOENT
    Dir[
      "exe/*", "lib/**/*.rb", "app/**/*", "config/**/*",
      "CHANGELOG.md", "LICENSE.txt", "README.md"
    ].select { |f| File.file?(f) }
  end
  s.bindir = "exe"
  s.executables = s.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  s.homepage = "https://github.com/mhenrixon/phlex-forms"
  s.metadata = {
    "source_code_uri" => "https://github.com/mhenrixon/phlex-forms",
    "changelog_uri" => "https://github.com/mhenrixon/phlex-forms/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/mhenrixon/phlex-forms/issues",
    "rubygems_mfa_required" => "true"
  }

  s.required_ruby_version = ">= 3.2"

  s.add_dependency "daisyui", "~> 1.2"
  s.add_dependency "phlex", "~> 2.0", ">= 2.0.0"
  s.add_dependency "tailwind_merge", "~> 1.0"
  s.add_dependency "zeitwerk", "~> 2.6"

  # `glyps` (icon components) is an OPTIONAL runtime integration, not a hard
  # dependency: phlex-forms ships a self-contained inline-SVG icon renderer by
  # default and auto-detects glyps when it is loaded. See PhlexForms::Configuration.
end
