# frozen_string_literal: true

require 'pathname'

module PathHelper
  module_function

  def project_root_path
    Pathname.new(File.expand_path('../..', __dir__))
  end

  def work_path
    project_root_path.join('work')
  end

  def original_repos_path
    work_path.join('original_repos')
  end

  def monorepo_path
    work_path.join('rspec-monorepo')
  end
end
