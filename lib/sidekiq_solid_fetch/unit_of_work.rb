module SidekiqSolidFetch
  class UnitOfWork
    attr_accessor :queue, :job, :config, :processing_queue

    def initialize(queue, job, config, processing_queue)
      @queue = queue
      @job = job
      @config = config
      @processing_queue = processing_queue
    end

    def acknowledge
      config.redis { |conn| conn.lrem(processing_queue, -1, job) }
    end

    def queue_name
      queue.delete_prefix("queue:")
    end

    def requeue
      config.redis do |conn|
        conn.multi do |multi|
          multi.lrem(processing_queue, -1, job)
          multi.lpush(queue, job)
        end
      end
    end
  end
end
