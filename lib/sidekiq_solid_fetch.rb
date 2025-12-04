require_relative "sidekiq_solid_fetch/version"
require_relative "sidekiq_solid_fetch/unit_of_work"
require_relative "sidekiq_solid_fetch/fetcher"

module SidekiqSolidFetch
  class Error < StandardError; end

  PROCESSING_QUEUE_PREFIX = "sidekiq_solid_fetch:processing"

  def self.enable!(config)
    config[:fetch_class] = SidekiqSolidFetch::Fetcher

    config.on(:startup) do
      Sidekiq.logger.info("SidekiqSolidFetch enabled")
      requeue_not_finished_jobs(config)
    end
  end

  def self.requeue_not_finished_jobs(config)
    Sidekiq.logger.info("SidekiqSolidFetch: Re-queueing not finished jobs from previous runs")

    count = 0
    Sidekiq.redis do |conn|
      config.queues.map { |q| "queue:#{q}" }.uniq.each do |queue|
        processing_queue_name = ::SidekiqSolidFetch.processing_queue_name(queue)
        while conn.lmove(processing_queue_name, queue, "RIGHT", "LEFT")
          count += 1
          Sidekiq.logger.info { "SidekiqSolidFetch: Moved job from #{processing_queue_name} back to #{queue}" }
        end
      end
    end

    Sidekiq.logger.info("SidekiqSolidFetch: Re-queued #{count} jobs from previous runs")
  end

  def self.processing_queue_name(queue)
    "#{PROCESSING_QUEUE_PREFIX}:#{queue}"
  end
end
