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

        res = conn.get('/solr/authors/autocomplete') do |req|
          req.params['q'] = str
          req.params['start'] = from if from && from >= 0
        end
        res = JSON.parse(res.body)['response']
        next_start = res['start'] + res['docs'].count
        res['next'] = next_start if next_start < res['numFound']
        res
      end

    end

  end

end

run App.freeze.app
