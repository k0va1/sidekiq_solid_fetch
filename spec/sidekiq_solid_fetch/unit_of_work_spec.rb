require "spec_helper"
require "sidekiq_solid_fetch/unit_of_work"

RSpec.describe SidekiqSolidFetch::UnitOfWork do
  let(:config) do
    cfg = Sidekiq::Config.new
    cfg.redis = {url: REDIS_URL}
    cfg.logger = nil
    cfg.queues = ["default"]
    cfg
  end
  let(:capsule) { config.default_capsule }
  let(:fetcher) { SidekiqSolidFetch::Fetcher.new(capsule) }

  let(:job_data) { {"class" => "TestWorker", "args" => [1, 2, 3]} }

  def push_job(queue, data = job_data)
    Sidekiq.redis { |conn| conn.lpush("queue:#{queue}", JSON.generate(data)) }
  end

  def queue_size(queue)
    Sidekiq.redis { |conn| conn.llen("queue:#{queue}") }
  end

  def processing_queue_size
    Sidekiq.redis { |conn| conn.llen(work.processing_queue) }
  end

  let(:work) do
    push_job("default")
    fetcher.retrieve_work
  end

  describe "#queue" do
    it "returns the source queue" do
      expect(work.queue).to eq("queue:default")
    end
  end

  describe "#job" do
    it "returns the job payload" do
      expect(JSON.parse(work.job)).to eq(job_data)
    end
  end

  describe "#queue_name" do
    it "returns queue name without prefix" do
      expect(work.queue_name).to eq("default")
    end
  end

  describe "#acknowledge" do
    it "removes job from processing queue" do
      expect(processing_queue_size).to eq(1)

      work.acknowledge

      expect(processing_queue_size).to eq(0)
    end

    it "does not affect original queue" do
      push_job("default") # Add another job
      expect(queue_size("default")).to eq(1)

      work.acknowledge

      expect(queue_size("default")).to eq(1)
    end
  end

  describe "#requeue" do
    it "moves job back to original queue" do
      expect(queue_size("default")).to eq(0)
      expect(processing_queue_size).to eq(1)

      work.requeue

      expect(queue_size("default")).to eq(1)
      expect(processing_queue_size).to eq(0)
    end

    it "uses atomic transaction" do
      work.requeue

      # Job should be back in original queue
      job = Sidekiq.redis { |conn| conn.rpop("queue:default") }
      expect(JSON.parse(job)).to eq(job_data)
    end
  end
end
