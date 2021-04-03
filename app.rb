# frozen_string_literal: true

require 'openid_connect'
require 'dotenv'

Dotenv.load

class GoogleClient < OpenIDConnect::Client
  def initialize
    super(
      identifier: ENV['CLIENT_ID'],
      secret: ENV['CLIENT_SECRET'],
      redirect_uri: 'http://localhost:3000/login/google/callback/code',
      authorization_endpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
      token_endpoint: 'https://oauth2.googleapis.com/token',
      userinfo_endpoint: 'https://openidconnect.googleapis.com/v1/userinfo',
    )
  end

  def self.jwk_json
    jwks = JSON.parse(
      OpenIDConnect.http_client.get_content('https://www.googleapis.com/oauth2/v3/certs')
    ).with_indifferent_access
    JSON::JWK::Set.new jwks[:keys]
  end
end

client = GoogleClient.new
authorization_uri = client.authorization_uri(
  scope: %i[profile openid],
  state: SecureRandom.hex(16),
  nonce: SecureRandom.hex(16)
)
`open "#{authorization_uri}"`

# Authorization Response
puts '# Enter Authorization Code'
code = gets.strip

client.authorization_code = code
access_token = client.access_token!
id_token = OpenIDConnect::ResponseObject::IdToken.decode access_token.id_token, GoogleClient.jwk_json

puts access_token
puts id_token.inspect
