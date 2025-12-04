require "sidekiq"
require "sidekiq/capsule"
require "sidekiq_solid_fetch"

REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_client do |config|
  config.redis = {url: REDIS_URL}
  config.logger = nil
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    Sidekiq.redis(&:flushdb)
  end
end
