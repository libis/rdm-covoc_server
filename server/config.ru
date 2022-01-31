# frozen_string_literal: true

require 'uri'
require 'json'
require 'roda'
require 'faraday'
require 'httpx/adapters/faraday'

class App < Roda
  plugin :json
  plugin :typecast_params

  conn = Faraday.new("http://localhost:7002", params: {indent: false}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.request :json
    f.response :json
    f.adapter :httpx
    # f.response :logger
  end

  route do |r|

    r.on 'autocomplete' do

      r.get 'authors' do

        str = typecast_params.str('q')
        next unless str

        from = typecast_params.int('from')
        per_page = typecast_params.int('per_page')
        per_page ||= 10

        res = conn.get('/solr/authors/autocomplete') do |req|
          req.params['rows'] = per_page
          req.params['q'] = str
          req.params['start'] = from if from && from >= 0
        end
        res = JSON.parse(res.body)['response']
        next_start = res['start'] + per_page
        prev_start = res['start'] - per_page
        prev_start = 0 if prev_start < 0
        res['next'] = next_start if next_start < res['numFound']
        res['prev'] = prev_start if res['start'] != 0
        res
      end

    end

  end

end

run App.freeze.app
