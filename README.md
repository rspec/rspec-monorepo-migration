[![Test](https://github.com/rspec/rspec-monorepo-migration/actions/workflows/test.yml/badge.svg)](https://github.com/rspec/rspec-monorepo-migration/actions/workflows/test.yml)

# RSpec monorepo migration

This repository contains the script for merging the RSpec repositories for [the monorepo migration project](https://github.com/rspec/rspec-core/issues/2509#issuecomment-939110402).

The core logic for merging repositories is in https://github.com/yujinakayama/repository_merger.

## Usage

You should clone this repository with `--recurse-submodules` since it manages the RSpec repositories for the migration as git submodules:

```
git clone --recurse-submodules git@github.com:rspec/rspec-monorepo-migration.git
```

Then run `exe/merge_rspec_repos` to import the history from the separate repos into `work/rspec-monorepo`:

```
bundle exec exe/merge_rspec_repos
```

Since the script imports the history with idempotence, you can run it again when there're new commits in the original repos:

```
git submodule foreach 'git fetch'
bundle exec exe/merge_rspec_repos
```
