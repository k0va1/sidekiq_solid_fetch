# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SidekiqSolidFetch is an open-source Ruby gem that provides a reliable fetch strategy for Sidekiq, similar to Sidekiq Pro's `super_fetch`. It uses Redis LMOVE to atomically move jobs from the queue to a processing queue, ensuring jobs aren't lost if a worker crashes.

## Commands

- **Install dependencies**: `bundle install`
- **Run all tests**: `bundle exec rake spec`
- **Run a single test file**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Run a single test by line**: `bundle exec rspec spec/path/to/file_spec.rb:LINE`
- **Lint code**: `bundle exec rake standard`
- **Auto-fix lint issues**: `bundle exec standardrb --fix`
- **Run all checks (tests + lint)**: `bundle exec rake`
- **Interactive console**: `bin/console`

## Architecture

### Core Components

- `SidekiqSolidFetch` (lib/sidekiq_solid_fetch.rb) - Main module with `enable!(config)` method to activate the custom fetcher
- `SidekiqSolidFetch::Fetcher` (lib/sidekiq_solid_fetch/fetcher.rb) - Custom Sidekiq fetcher implementing reliable queue processing

### Fetcher Design

The Fetcher uses Redis LMOVE to atomically move jobs from the source queue to a per-worker processing queue (`processing:queue:{name}:{identity}`). This ensures:
- Jobs are never lost if a worker crashes mid-execution
- Unfinished jobs can be requeued via `bulk_requeue`

Key classes:
- `Fetcher` - Implements Sidekiq's fetch interface with `retrieve_work` and `bulk_requeue`
- `UnitOfWork` - Struct wrapping a job with `acknowledge` and `requeue` methods

### Queue Modes

- **Strict mode** (`cap.mode == :strict`) - Processes queues in defined order
- **Weighted mode** (default) - Shuffles queues to distribute load

## Requirements

- Ruby >= 3.1.0
- Sidekiq >= 7.0
