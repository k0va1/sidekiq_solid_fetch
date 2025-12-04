require "spec_helper"

RSpec.describe SidekiqSolidFetch::Fetcher do
  let(:config) do
    cfg = Sidekiq::Config.new
    cfg.redis = {url: REDIS_URL}
    cfg.queues = queues
    cfg.logger = nil
    cfg
  end
  let(:capsule) { config.default_capsule }
  let(:queues) { ["default", "critical"] }

  subject(:fetcher) { described_class.new(capsule) }

  def push_job(queue, job_data = {"class" => "TestWorker", "args" => []})
    Sidekiq.redis { |conn| conn.lpush("queue:#{queue}", JSON.generate(job_data)) }
  end

  def queue_size(queue)
    Sidekiq.redis { |conn| conn.llen("queue:#{queue}") }
  end

  def processing_queue_size(queue)
    Sidekiq.redis { |conn| conn.llen(SidekiqSolidFetch.processing_queue_name("queue:#{queue}")) }
  end

  describe "#retrieve_work" do
    it "returns nil when queues are empty" do
      expect(fetcher.retrieve_work).to be_nil
    end

    it "returns UnitOfWork when job exists" do
      push_job("default", {"class" => "TestWorker", "args" => [1, 2]})

      work = fetcher.retrieve_work

      expect(work).to be_a(SidekiqSolidFetch::UnitOfWork)
      expect(work.queue).to eq("queue:default")
      expect(JSON.parse(work.job)).to eq({"class" => "TestWorker", "args" => [1, 2]})
    end

    it "moves job from queue to processing queue atomically" do
      push_job("default")

      expect(queue_size("default")).to eq(1)
      expect(processing_queue_size("default")).to eq(0)

      fetcher.retrieve_work

      expect(queue_size("default")).to eq(0)
      expect(processing_queue_size("default")).to eq(1)
    end

    it "processes queues in order (strict mode)" do
      push_job("critical", {"class" => "CriticalWorker"})
      push_job("default", {"class" => "DefaultWorker"})

      # Strict mode processes queues in defined order
      work = fetcher.retrieve_work
      expect(JSON.parse(work.job)["class"]).to eq("DefaultWorker")
    end

    it "retrieves jobs from first available queue" do
      push_job("critical", {"class" => "CriticalWorker"})

      work = fetcher.retrieve_work
      expect(work.queue).to eq("queue:critical")
    end
  end

  describe "#bulk_requeue" do
    it "moves jobs from processing queues back to original queues" do
      push_job("default", {"class" => "Worker1"})
      push_job("default", {"class" => "Worker2"})

      # Simulate jobs being fetched
      fetcher.retrieve_work
      fetcher.retrieve_work

      expect(queue_size("default")).to eq(0)
      expect(processing_queue_size("default")).to eq(2)

      fetcher.bulk_requeue([])

      expect(queue_size("default")).to eq(2)
      expect(processing_queue_size("default")).to eq(0)
    end

    it "requeues jobs from multiple queues" do
      push_job("default")
      push_job("critical")

      fetcher.retrieve_work
      fetcher.retrieve_work

      fetcher.bulk_requeue([])

      expect(queue_size("default")).to eq(1)
      expect(queue_size("critical")).to eq(1)
    end

    it "does nothing when processing queues are empty" do
      expect { fetcher.bulk_requeue([]) }.not_to raise_error
    end
  end
end
