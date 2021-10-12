# frozen_string_literal: true

require 'repository_merger'
require 'repository_merger/github_issue_reference'

class RSpecMonorepoMigration
  WORK_DIR = 'work'

  ORIGINAL_REPO_PATHS = %w[
    rspec
    rspec-core
    rspec-expectations
    rspec-mocks
    rspec-support
  ].map { |name| File.join('original_repos', name) }.freeze

  MONOREPO_PATH = 'rspec-monorepo'

  TAG_NAMES_UNREACHABLE_FROM_TARGET_BRANCHES = %w[
    v2.0.0.beta.9
    v3.5.0.beta2
  ].freeze

  attr_reader :verbose_logging, :current_import_phase_number

  def initialize(verbose_logging:)
    @verbose_logging = verbose_logging
    @current_import_phase_number = 1
  end

  def run
    Dir.chdir(work_dir) do
      import_tags_unreachable_from_target_branches
      import_target_branches
      import_all_tags
      run_git_gc
    end
  rescue Interrupt
    puts 'Aborting...'
    exit(1)
  end

  def work_dir
    Dir.mkdir(WORK_DIR) unless Dir.exist?(WORK_DIR)
    WORK_DIR
  end

  def import_tags_unreachable_from_target_branches
    TAG_NAMES_UNREACHABLE_FROM_TARGET_BRANCHES.each do |tag_name|
      tags = configuration.original_repos.map { |repo| repo.tag_for(tag_name) }.compact

      repo_merger.merge_commit_history_of(
        tags,
        commit_message_conversion: method(:convert_commit_message),
        progress_title: "[#{current_import_phase_number}/#{total_import_phase_count}: #{tag_name}]"
      )

      # We need to import the tags here before importing target branches
      # so that the tags will reference right commits.
      repo_merger.import_tags(tags, tag_name_conversion: method(:convert_tag_name))

      increment_import_phase_number
    end
  end

  def import_target_branches
    target_branch_names.each do |branch_name|
      repo_merger.merge_commit_history_of_branches_named(
        branch_name,
        commit_message_conversion: method(:convert_commit_message),
        progress_title: "[#{current_import_phase_number}/#{total_import_phase_count}: #{branch_name}]"
      )

      increment_import_phase_number
    end
  end

  def import_all_tags
    repo_merger.import_all_tags(tag_name_conversion: method(:convert_tag_name))
  end

  def run_git_gc
    Dir.chdir(configuration.monorepo_path) do
      # Clear index and working tree since they're cluttered after the merge
      `git reset --hard`

      # Merged repos without GC tend to have large volume
      puts 'Running `git gc`...'
      system('git gc')
    end
  end

  def increment_import_phase_number
    @current_import_phase_number += 1
  end

  def total_import_phase_count
    TAG_NAMES_UNREACHABLE_FROM_TARGET_BRANCHES.size + target_branch_names.size
  end

  def target_branch_names
    @target_branch_names ||= begin
      all_branch_names = configuration.original_repos.flat_map { |repo| repo.branches.map(&:name) }.uniq.sort
      ['origin/main'] + all_branch_names.grep(%r{\Aorigin/\d+-\d+-(maintenance|stable)\z})
    end
  end

  def convert_commit_message(original_commit)
    message = RepositoryMerger::GitHubIssueReference.convert_repo_local_references_to_absolute_ones_in(
      original_commit.message,
      username: 'rspec',
      repo_name: original_commit.repo.name
    )

    lines = message.split(/\r?\n/)

    scope = original_commit.repo.name.sub(/\Arspec-/, '')
    lines.first.prepend("[#{scope}] ")

    if lines.size == 1
      lines << ''
    else
      lines.concat([
        '',
        '---'
      ])
    end

    original_commit_url = "https://github.com/rspec/#{original_commit.repo.name}/commit/#{original_commit.id}"
    lines << "This commit was imported from #{original_commit_url}."

    lines.join("\n")
  end

  def convert_tag_name(original_tag)
    tag_name = original_tag.name
    tag_name = "v#{tag_name}" if tag_name.match?(/\A\d+\.\d+\.\d+/)

    scope = original_tag.repo.name.sub(/\Arspec-/, '')

    "#{tag_name}-#{scope}"
  end

  def repo_merger
    @repo_merger ||= RepositoryMerger.new(configuration)
  end

  def configuration
    @configuration ||= RepositoryMerger::Configuration.new(
      original_repo_paths: ORIGINAL_REPO_PATHS,
      monorepo_path: MONOREPO_PATH,
      verbose_logging: verbose_logging
    )
  end
end
