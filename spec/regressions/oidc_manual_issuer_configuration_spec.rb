# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OIDC manual endpoint issuer configuration' do
  it 'keeps manual endpoints while setting the issuer explicitly' do
    config = OidcConfig.build(
      'OIDC_CLIENT_ID' => 'client-abc',
      'OIDC_CLIENT_SECRET' => 'secret-xyz',
      'APPLICATION_URL' => 'http://dawarich.example.com',
      'OIDC_ISSUER' => 'https://auth.example.com',
      'OIDC_HOST' => 'auth.example.com',
      'OIDC_SCHEME' => 'https',
      'OIDC_AUTHORIZATION_ENDPOINT' => '/api/oidc/authorization',
      'OIDC_TOKEN_ENDPOINT' => '/api/oidc/token',
      'OIDC_USERINFO_ENDPOINT' => '/api/oidc/userinfo'
    )

    expect(config[:issuer]).to eq('https://auth.example.com')
    expect(config).not_to have_key(:discovery)
    expect(config[:client_options]).to include(
      host: 'auth.example.com',
      authorization_endpoint: '/api/oidc/authorization',
      token_endpoint: '/api/oidc/token',
      userinfo_endpoint: '/api/oidc/userinfo'
    )
  end
end
