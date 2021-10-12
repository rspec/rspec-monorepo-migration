# frozen_string_literal: true

require 'open3'
require 'shellwords'

module GitHelper
  class GitError < StandardError
    def initialize(command, stderr)
      super("#{stderr.chomp} (`#{command.shelljoin}` in #{Dir.getwd})")
    end
  end

  module_function

  def git(arg)
    args = arg.is_a?(Array) ? arg : arg.shellsplit
    command = ['git'] + args
    stdout, stderr, status = Open3.capture3(*command)
    raise GitError.new(command, stderr) unless status.success?
    stdout.each_line.map { |line| line.sub(/ +$/, '') }.join
  end
end
