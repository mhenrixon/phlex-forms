# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/**/*_spec.rb"
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

# Formatted release output — headered sections + status markers, matching the
# sibling gems (glyphs/pgbus) so a release reads at a glance.
module ReleaseHelpers
  def info(msg)    = puts "\e[34m→\e[0m #{msg}"
  def success(msg) = puts "\e[32m✓\e[0m #{msg}"
  def skip(msg)    = puts "\e[33m⊘\e[0m #{msg} \e[33m(skipped)\e[0m"
  def warn(msg)    = puts "\e[33m⚠\e[0m #{msg}"
  def error(msg)   = puts "\e[31m✗\e[0m #{msg}"
  def header(msg)  = puts "\n\e[1;36m#{msg}\e[0m\n#{'─' * msg.length}"
end

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

desc "Release a new version (rake 'release[0.2.0]' or 'release[0.2.0,force]')"
task :release, %i[version force] do |_t, args|
  include ReleaseHelpers

  require_relative "lib/phlex_forms/version"

  new_version = args[:version]
  abort "\e[31mUsage: rake release[X.Y.Z] or rake release[X.Y.Z,force]\e[0m" unless new_version

  force = args[:force]&.to_s&.downcase == "force"

  branch = `git branch --show-current`.strip
  abort "\e[31mAborting: must be on main to release (currently on #{branch})\e[0m" unless branch == "main"

  dirty = `git status --porcelain`.strip
  abort "\e[31mAborting: working directory is not clean.\e[0m\n#{dirty}" unless dirty.empty?

  current = PhlexForms::VERSION
  # `pre` releases the CURRENT version as a prerelease; otherwise infer from the tag.
  prerelease = new_version.match?(/alpha|beta|rc|pre/) || new_version == "pre"
  if new_version == "pre"
    new_version = current
    prerelease = true
  end

  tag = "v#{new_version}"
  version_file = "lib/phlex_forms/version.rb"

  title = "Release #{tag}"
  title += " (force)" if force
  header title
  info "Current version: #{current}"
  info "New version:     #{new_version}"
  info "Pre-release:     #{prerelease}"

  # Step 0: Force cleanup — delete an existing release + tag so a re-cut points
  # at the CURRENT main (not the stale commit the old tag referenced).
  if force
    header "Force cleanup"
    if system("gh release view #{tag} >/dev/null 2>&1")
      sh("gh release delete #{tag} --yes --cleanup-tag")
      success "Deleted release and remote tag #{tag}"
    else
      skip "No release #{tag} to delete"
    end

    if system("git rev-parse #{tag} >/dev/null 2>&1")
      sh("git tag -d #{tag}")
      success "Deleted local tag #{tag}"
    else
      skip "No local tag #{tag} to delete"
    end
  end

  # Step 1: Update the version file.
  header "Version"
  if new_version == current
    skip "Version already #{new_version}"
  else
    File.write(version_file, File.read(version_file).sub(/VERSION = ".*"/, %(VERSION = "#{new_version}")))
    success "Updated #{version_file}"
  end

  # Step 2: Sync the committed docs lockfile's path-gem pin.
  #
  # The gem's own Gemfile.lock is gitignored (correct for a library — it must not
  # lock its own deps), so it is NEVER bundled or staged here. But docs/Gemfile.lock
  # IS committed (reproducible docs image), and it path-pins phlex-forms — a bump
  # leaves that pin stale.
  #
  # We surgically string-edit ONLY the phlex-forms pin rather than `cd docs &&
  # bundle install`: docs/Gemfile.lock carries a broad PLATFORMS list (…-gnu /
  # …-musl / arm-linux) for which a platform gem like `thruster` ships no variant,
  # so a full re-resolve fails with "Could not find gems matching … valid for all
  # resolution platforms" on any machine whose cache lacks those exact gems —
  # aborting the release. A targeted pin edit is deterministic on any machine and
  # produces the minimal 2-line diff (the PATH spec + the DEPENDENCIES pin). Same
  # fix pgbus uses.
  header "Docs lockfile"
  docs_lock = "docs/Gemfile.lock"
  synced_lockfiles = []
  if File.exist?(docs_lock)
    content = File.read(docs_lock)
    # Matches both the PATH-source spec ("    phlex-forms (X.Y.Z)") and the
    # DEPENDENCIES pin ("  phlex-forms (X.Y.Z)"), leaving everything else untouched.
    bumped = content.gsub(/^(\s+phlex-forms) \([^)]*\)$/, "\\1 (#{new_version})")
    if bumped == content
      skip "#{docs_lock} — phlex-forms pin already #{new_version}"
    else
      File.write(docs_lock, bumped)
      synced_lockfiles << docs_lock
      success "Bumped phlex-forms pin in #{docs_lock}"
    end
  else
    skip "#{docs_lock} not present"
  end

  # Step 3: Verify the gem builds cleanly (--strict: open-ended deps, bad
  # metadata, and other spec warnings fail the build).
  header "Build verification"
  sh("gem build phlex-forms.gemspec --strict")
  sh("rm -f phlex-forms-*.gem")
  success "Gem builds cleanly"

  # Step 4: Commit the version bump (+ the synced docs pin).
  header "Git commit"
  paths_to_stage = [version_file, *synced_lockfiles]
  changed = paths_to_stage.any? do |path|
    !`git diff #{path}`.strip.empty? || !`git diff --cached #{path}`.strip.empty?
  end
  if changed
    paths_to_stage.each { |path| sh("git add #{path}") }
    sh("git commit -m 'chore: bump version to #{new_version}'")
    success "Committed version bump"
  else
    skip "No version change to commit"
  end

  # Step 5: Push to origin.
  header "Git push"
  local_sha = `git rev-parse HEAD`.strip
  remote_sha = `git rev-parse origin/main 2>/dev/null`.strip
  if local_sha == remote_sha
    skip "origin/main already at #{local_sha[0..6]}"
  else
    sh("git push origin main")
    success "Pushed to origin/main"
  end

  # Step 6: Create the GitHub release (CI publishes to RubyGems + deploys docs).
  header "Release"
  tag_exists = system("git rev-parse #{tag} >/dev/null 2>&1")
  release_exists = system("gh release view #{tag} >/dev/null 2>&1")
  pre_flag = prerelease ? "--prerelease" : ""

  if release_exists
    skip "Release #{tag} already exists (use force to re-create)"
  elsif tag_exists
    info "Tag #{tag} exists, creating release from it"
    sh("gh release create #{tag} --generate-notes #{pre_flag}".strip)
    success "Release #{tag} created from existing tag"
  else
    sh("gh release create #{tag} --generate-notes --target main #{pre_flag}".strip)
    success "Release #{tag} created"
  end

  puts ""
  success "\e[1mRelease #{tag} complete!\e[0m CI will handle the rest:"
  puts "    • Run tests"
  puts "    • Build + verify gem"
  puts "    • Sign with Sigstore"
  puts "    • Publish to RubyGems"
  puts "    • Upload assets to the release"
  puts "    • Deploy the docs site"
end

task default: %i[spec rubocop]
