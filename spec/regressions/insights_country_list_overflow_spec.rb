# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Insights country list layout', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
    create(:stat, user:, year: 2026, month: 3, distance: 1000)
    12.times do |index|
      create(
        :point,
        user:,
        country_name: "Country #{index}",
        timestamp: Time.zone.local(2026, 3, index + 1, 12).to_i
      )
    end
  end

  it 'bounds long country lists beside the calendar on desktop' do
    get map_residency_path(year: 2026)

    document = Nokogiri::HTML(response.body)
    country_card = document.at_css('[data-testid="residency-country-card"]')
    country_list = document.at_css('[data-testid="residency-country-list"]')

    expect(country_card['class']).to include('lg:max-h-64')
    expect(country_list['class']).to include('lg:overflow-y-auto')
    expect(country_list['class']).to include('flex-1')
  end
end
