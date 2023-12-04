# frozen_string_literal: true

require 'faraday'
require 'httpx/adapters/faraday'

module OpenAire
  OA_AUTH_HOST = ENV['OAAAI_HOST'] || 'https://aai.openaire.eu'
  OA_HOST = ENV['OPEN_AIRE_HOST'] || 'https://api.openaire.eu'
  LOGGING = ENV['LOG_LEVEL'] == 'debug'

  def self.openAireCredentials
    File.read(ENV['OPEN_AIRE_CREDS_FILE']).strip
  end

  def self.oaauth
    Faraday.new(OA_AUTH_HOST, ssl: {verify: false}) do |f|
      f.use Faraday::Request::UrlEncoded
      f.request :json
      f.response :json
      f.response :logger, nil, {headers: true, bodies: false} if LOGGING
      f.adapter :httpx
    end
  end

  def self.oa
    Faraday.new(OA_HOST, ssl: {verify: false}) do |f|
      f.use Faraday::Request::UrlEncoded
      f.response :logger, nil, {headers: true, bodies: false} if LOGGING
      f.adapter :httpx
    end
  end

  def self.resTokenR
    @oaauth ||= oaauth
    @openAireCredentials ||= openAireCredentials
    @oaauth.post('/oidc/token', nil, ) do |req|
      req.headers[:Authorization] = 'Basic ' + @openAireCredentials
      req.params['grant_type'] = 'client_credentials'
      req.options.timeout = 2
    end
  end

  def self.authorization
    @oamutex ||= Mutex.new
    @aoexpires ||= Time.now
    @oamutex.synchronize do
      if !@oatoken || @aoexpires < Time.now
        resToken = resTokenR.body
        @aoexpires = Time.now + resToken['expires_in'].to_i - 60
        @oatoken = resToken['access_token']
      end
    end
    'Bearer ' + @oatoken
  end

  def self.search(path)
    @oa ||= oa
    res = @oa.get("/search" + path, nil, ) do |req|
      req.headers[:Authorization] = authorization
      yield req
    end
  end

end
