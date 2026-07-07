# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/**/*_spec.rb"
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

desc "Build gem and verify contents"
task :build do
  sh("gem build phlex-forms.gemspec --strict")
  gem_file = Dir["phlex-forms-*.gem"].first
  abort "Gem file not found after build" unless gem_file

  sh("gem unpack #{gem_file} --target /tmp/phlex-forms-verify")
  puts "\n=== Gem contents ==="
  sh("find /tmp/phlex-forms-verify -type f | sort")
  sh("rm -rf /tmp/phlex-forms-verify #{gem_file}")
end

desc "Release a new version (rake 'release[0.1.0]' or 'release[0.1.0,force]')"
task :release, %i[version force] do |_t, args|
  new_version = args[:version]
  abort "Usage: rake 'release[X.Y.Z]'" unless new_version

  require_relative "lib/phlex_forms/version"
  current = PhlexForms::VERSION
  force = args[:force].to_s.downcase == "force"
  prerelease = new_version.match?(/alpha|beta|rc|pre/)
  tag = "v#{new_version}"

  branch = `git branch --show-current`.strip
  abort "Aborting: must be on main (currently #{branch})" unless branch == "main"
  dirty = `git status --porcelain`.strip
  abort "Aborting: working directory not clean.\n#{dirty}" unless dirty.empty?

  # Force cleanup of an existing release/tag.
  if force
    sh("gh release delete #{tag} --yes --cleanup-tag") if system("gh release view #{tag} >/dev/null 2>&1")
    sh("git tag -d #{tag}") if system("git rev-parse #{tag} >/dev/null 2>&1")
  end

  # Bump the version file.
  if new_version == current
    puts "Version already #{new_version}"
  else
    file = "lib/phlex_forms/version.rb"
    File.write(file, File.read(file).sub(/VERSION = ".*"/, %(VERSION = "#{new_version}")))
    sh("bundle install --quiet")
    sh("git add #{file} Gemfile.lock")
    sh("git commit -m 'chore: bump version to #{new_version}'")
  end

  # Verify the gem builds cleanly.
  sh("gem build phlex-forms.gemspec --strict")
  sh("rm -f phlex-forms-*.gem")

  # Push and create the release; CI publishes to RubyGems.
  sh("git push origin main") unless `git rev-parse HEAD`.strip == `git rev-parse origin/main 2>/dev/null`.strip
  pre = prerelease ? "--prerelease" : ""
  if system("gh release view #{tag} >/dev/null 2>&1")
    puts "Release #{tag} already exists (use force to re-create)"
  else
    sh("gh release create #{tag} --generate-notes --target main #{pre}".strip)
  end

  puts "\nRelease #{tag} created. CI will test, build, sign, and publish to RubyGems."
end

task default: %i[spec rubocop]
