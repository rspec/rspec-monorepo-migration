# frozen_string_literal: true

RSpec.configure do |config|
  config.after(:suite) do
    `git submodule foreach 'git switch main' 2>&1`
  end
end
