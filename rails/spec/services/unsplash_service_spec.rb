require 'rails_helper'

RSpec.describe UnsplashService do
  let(:api_key) { "fake_key" }
  let(:service) { described_class.new(api_key: api_key) }

  describe "#search" do
    let(:query) { "mountains" }
    let(:response_body) do
      {
        results: [
          {
            id: "123",
            alt_description: "A mountain",
            urls: { regular: "https://example.com/mountain.jpg" },
            user: {
              name: "John Doe",
              links: { html: "https://unsplash.com/@johndoe" }
            }
          }
        ]
      }.to_json
    end

    it "returns an array of mapped photos" do
      response = instance_double(Net::HTTPSuccess, body: response_body)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(Net::HTTP).to receive(:start).and_return(response)

      result = service.search(query)
      expect(result).to be_an(Array)
      expect(result.first[:url]).to eq("https://example.com/mountain.jpg")
      expect(result.first[:photographer]).to eq("John Doe")
      expect(result.first[:photographer_url]).to include("utm_source=leonardo_rails_app")
      expect(result.first[:html_attribution]).to include("Photo by <a href='https://unsplash.com/@johndoe?utm_source=leonardo_rails_app&utm_medium=referral'>John Doe</a> on <a href='https://unsplash.com/?utm_source=leonardo_rails_app&utm_medium=referral'>Unsplash</a>")
    end

    it "handles API errors gracefully" do
      response = instance_double(Net::HTTPUnauthorized, body: "Unauthorized", code: "401")
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(Net::HTTP).to receive(:start).and_return(response)

      result = service.search(query)
      expect(result).to be_a(Hash)
      expect(result[:error]).to include("Unsplash API error: 401 Unauthorized")
    end
  end

  describe "#get_by_id" do
    let(:photo_id) { "abc123" }
    let(:response_body) do
      {
        id: "abc123",
        alt_description: "A lake",
        urls: { regular: "https://example.com/lake.jpg" },
        user: {
          name: "Jane Smith",
          links: { html: "https://unsplash.com/@janesmith" }
        }
      }.to_json
    end

    it "returns a single mapped photo" do
      response = instance_double(Net::HTTPSuccess, body: response_body)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(Net::HTTP).to receive(:start).and_return(response)

      result = service.get_by_id(photo_id)
      expect(result).to be_a(Hash)
      expect(result[:url]).to eq("https://example.com/lake.jpg")
      expect(result[:photographer]).to eq("Jane Smith")
    end

    it "handles errors for get_by_id" do
      response = instance_double(Net::HTTPNotFound, body: "Not Found", code: "404")
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(Net::HTTP).to receive(:start).and_return(response)

      result = service.get_by_id(photo_id)
      expect(result).to be_a(Hash)
      expect(result[:error]).to include("Unsplash API error: 404 Not Found")
    end
  end
end
