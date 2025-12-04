# SidekiqSolidFetch

A reliable fetch strategy for Sidekiq that ensures jobs are never lost, even if a worker crashes mid-execution. This is an open-source implementation similar to Sidekiq Pro's `super_fetch`.

## How It Works

SidekiqSolidFetch uses Redis `LMOVE` command to atomically move jobs from the queue to a per-worker processing queue. This approach ensures:

- **No job loss**: Jobs are moved (not copied) to a processing queue before execution. If a worker crashes, the job remains in the processing queue.
- **Automatic recovery**: On startup, any unfinished jobs from previous runs are automatically requeued.
- **Graceful shutdown**: When Sidekiq shuts down, in-progress jobs are moved back to their original queues.

### Flow

1. Worker fetches a job → job is atomically moved from `queue:default` to `sidekiq_solid_fetch:processing:queue:default`
2. Worker processes the job successfully → job is removed from the processing queue
3. Worker crashes → job stays in the processing queue
4. On next startup → jobs in processing queues are moved back to their original queues

## Installation

Add to your Gemfile:

```ruby
gem "sidekiq_solid_fetch"
```

Then run:

```bash
bundle install
```

## Usage

Enable SidekiqSolidFetch in your Sidekiq configuration:

```ruby
# config/initializers/sidekiq.rb (Rails)
# or wherever you configure Sidekiq

require "sidekiq_solid_fetch"

Sidekiq.configure_server do |config|
  SidekiqSolidFetch.enable!(config)
end
```

That's it! SidekiqSolidFetch will now handle job fetching with crash recovery.

## Requirements

- Ruby >= 3.1.0
- Sidekiq >= 7.0

## Development

After checking out the repo, run `bin/setup` to install dependencies.

```bash
# Run tests
docker compose up -d
make test

# Run linter
make lint-fix
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/k0va1/sidekiq_solid_fetch.

## License

The gem is available as open source under the terms of the MIT License.
