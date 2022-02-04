# frozen_string_literal: true

require 'uri'
require 'json'
require 'roda'
require 'faraday'
require 'httpx/adapters/faraday'

class App < Roda
  opts[:add_script_name] = 'covoc'
  plugin :json
  plugin :typecast_params
  plugin :public

  solr_host = ENV['SOLR_HOST'] || 'http://localhost:8983'

  conn = Faraday.new(solr_host, params: {indent: false}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.request :json
    f.response :json
    f.adapter :httpx
    f.response :logger if ENV['DEBUG_LOG']
  end

  route do |r|

    r.public

    r.get 'authors' do

      str = typecast_params.str('q')
      next unless str

      from = typecast_params.int('from')
      per_page = typecast_params.int('per_page')
      per_page ||= 10

      res = case str
      when /^(\b(u?\d*))+$/
        conn.get('/solr/authors/number') do |req|
          req.params['rows'] = per_page
          req.params['q'] = str
          req.params['start'] = from if from && from >= 0
        end
      when /^(\b\w*(\.|@)\w*)+$/
        conn.get('/solr/authors/email') do |req|
          req.params['rows'] = per_page
          req.params['q'] = str
          req.params['start'] = from if from && from >= 0
        end
      when /^(\b[a-zA-z]+,?)+$/
        conn.get('/solr/authors/name') do |req|
          req.params['rows'] = per_page
          req.params['q'] = str
          req.params['start'] = from if from && from >= 0
        end
      else
        conn.get('/solr/authors/any') do |req|
          req.params['rows'] = per_page
          req.params['q'] = str
          req.params['start'] = from if from && from >= 0
        end
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

run App.freeze.app
