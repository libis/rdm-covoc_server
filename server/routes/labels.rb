# frozen_string_literal: true

require 'faraday'
require 'httpx/adapters/faraday'

class App

  logging = ENV['LOG_LEVEL'] == 'debug'
  solr_host = ENV['SOLR_HOST'] || 'http://localhost:8983'

  solr = Faraday.new(solr_host, params: {indent: false}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.request :json
    f.response :json
    f.response :logger, nil, {headers: true, bodies: false} if logging
    f.adapter :httpx
  end

  hash_branch 'labels' do |r|
    r.get do

      min_from = 0
      min_page = 1
      default_from = 0
      default_page = 10

      # Get parameters
      str = typecast_params.str('q')
      return NO_RESULT unless str

      from = [min_from, typecast_params.int('from') || default_from].max
      per_page = [min_page, typecast_params.int('per_page') || default_page].max
      schemes = (typecast_params.str('scheme') || '').split(',').map(&:strip).reject(&:empty?)

      # Perform Solr search
      p = {
        start: from,
        rows: per_page,
        q: str
      }
      p[:fq] = "scheme:(#{schemes.map { |s| "\"#{s}\"" }.join(' OR ')})" unless schemes.empty?

      res = solr.get('/solr/labels/any') do |req|
        req.params.merge!(p)
      end

      # Check response error
      unless res&.success?
        return NO_RESULT
      end

      res = res.body['response']
      return NO_RESULT unless res

      # Set start, next and previous values
      next_start = res['start'] + per_page
      prev_start = [min_from, res['start'] - per_page].max
      res['next'] = next_start if next_start < res['numFound'] + min_from
      res['prev'] = prev_start if res['start'] != min_from

      # Finally, return the response
      res

    end
  end
end
