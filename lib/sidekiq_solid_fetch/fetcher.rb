require "sidekiq"
require "sidekiq/component"
require "sidekiq/capsule"

module SidekiqSolidFetch
  class Fetcher
    include Sidekiq::Component

    def initialize(cap)
      raise ArgumentError, "missing queue list" unless cap.queues
      @config = cap
      @strictly_ordered_queues = cap.mode == :strict
      @queues = config.queues.map { |q| "queue:#{q}" }
      @queues.uniq! if @strictly_ordered_queues
    end

    def retrieve_work
      queues_cmd.each do |queue|
        processing_queue_name = ::SidekiqSolidFetch.processing_queue_name(queue)
        work = redis do |conn|
          conn.lmove(queue, processing_queue_name, "RIGHT", "LEFT")
        end

        return ::SidekiqSolidFetch::UnitOfWork.new(queue, work, config, processing_queue_name) if work
      end
      nil
    end

    def bulk_requeue(*)
      logger.info("SidekiqSolidFetch: Re-queueing terminated jobs")

      count = 0
      redis do |conn|
        queues_cmd.each do |queue|
          processing_queue_name = ::SidekiqSolidFetch.processing_queue_name(queue)
          while conn.lmove(processing_queue_name, queue, "RIGHT", "LEFT")
            count += 1
            logger.info { "SidekiqSolidFetch: Moving job from #{processing_queue_name} back to #{queue}" }
          end
        end
      end
      logger.info("SidekiqSolidFetch: Re-queued #{count} jobs")
    rescue => ex
      logger.warn("SidekiqSolidFetch: Failed to requeue jobs: #{ex.message}")
    end

    def queues_cmd
      if @strictly_ordered_queues
        @queues
      else
        permute = @queues.shuffle
        permute.uniq!
        permute
      end
    end
  end
end
