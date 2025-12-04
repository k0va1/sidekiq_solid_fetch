require "spec_helper"

RSpec.describe SidekiqSolidFetch do
  it "has a version number" do
    expect(SidekiqSolidFetch::VERSION).not_to be_nil
  end

  describe ".enable!" do
    let(:config) do
      cfg = Sidekiq::Config.new
      cfg.redis = {url: REDIS_URL}
      cfg.logger = nil
      cfg.queues = ["default"]
      cfg
    end

    it "sets the fetch_class to Fetcher" do
      described_class.enable!(config)
      expect(config[:fetch_class]).to eq(SidekiqSolidFetch::Fetcher)
    end
  end
end
