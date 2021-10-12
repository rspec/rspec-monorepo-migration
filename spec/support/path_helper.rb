# frozen_string_literal: true

require 'pathname'

module PathHelper
  module_function

  def project_root_path
    Pathname.new(File.expand_path('../..', __dir__))
  end

  def tmp_path
    project_root_path.join('tmp')
  end

  def work_path
    project_root_path.join('work')
  end
end
