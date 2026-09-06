# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Nominatim naming and nearby search' do
  let(:user) { create(:user) }
  let(:place) { create(:place, user: user, name: Place::DEFAULT_NAME, lonlat: 'POINT(13.405 52.52)') }
  let(:data) do
    {
      'lat' => '52.52', 'lon' => '13.405', 'osm_id' => 123, 'type' => 'house',
      'display_name' => '51, Example Road, Berlin, Germany',
      'address' => { 'house_number' => '51', 'road' => 'Example Road', 'city' => 'Berlin', 'country' => 'Germany' }
    }
  end
  let(:result) { double(data: data) }

  before do
    allow(DawarichSettings).to receive(:reverse_geocoding_enabled?).and_return(true)
    allow(Geocoding::Search).to receive(:call).and_return([result])
  end

  it 'names an unnamed place from the flat provider address' do
    Places::NameFetcher.new(place).call

    expect(place.reload.name).to eq('Example Road, 51, Berlin')
    expect(place.city).to eq('Berlin')
    expect(place.country).to eq('Germany')
  end

  it 'preserves a manual name while updating its location details' do
    place.update!(name: 'My home', user_named: true)

    Places::NameFetcher.new(place).call

    expect(place.reload.name).to eq('My home')
    expect(place.city).to eq('Berlin')
  end

  it 'uses the street address instead of a bare house number in reverse lookup' do
    ReverseGeocoding::Places::FetchData.new(place.id).call

    expect(place.reload.name).to eq('Example Road 51 (House)')
  end

  %i[nominatim locationiq].each do |provider|
    it "bounds #{provider} text search near the requested coordinates" do
      config = Geocoding::Config.new(source: :user, provider: provider, host: 'geocoder.example.test',
                                     api_key: 'synthetic')
      allow(Geocoding::Config).to receive(:for).with(user).and_return(config)

      results = Places::Search.new(user: user, query: 'Example', latitude: 52.52, longitude: 13.405, radius: 1).call

      expect(results.size).to eq(1)
      expect(results.first).to include(latitude: 52.52, longitude: 13.405)
      expect(Geocoding::Search).to have_received(:call) do |**options|
        expect(options[:params][:bounded]).to eq(1)
        west, north, east, south = options[:params][:viewbox].split(',').map(&:to_f)
        expect(west).to be < 13.405
        expect(east).to be > 13.405
        expect(south).to be < 52.52
        expect(north).to be > 52.52
        expect(options).not_to have_key(:bias)
      end
    end
  end

  [nil, [], [1], true, 42, 'legacy'].each do |data|
    it "ignores stored geodata of shape #{data.inspect}" do
      expect(Geocoding::ResultNormalizer.from_data(data)).to eq(properties: {}, coords: nil)
    end
  end
end
