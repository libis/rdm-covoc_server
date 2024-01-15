# frozen_string_literal: true

require 'faraday'
require 'httpx/adapters/faraday'

class App

  logging = ENV['LOG_LEVEL'] == 'debug'
  solr_host = ENV['SOLR_HOST'] || 'http://localhost:8983'
  lirias_host = ENV['LIRIAS_HOST'] || 'https://lirias2repo.kuleuven.be'

  solr = Faraday.new(solr_host, params: {indent: false}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.request :json
    f.response :json
    f.response :logger, nil, {headers: true, bodies: false} if logging
    f.adapter :httpx
  end

  hash_branch 'authors' do |r|
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

      # Perform Solr search
      p = {
        start: from,
        rows: per_page,
        q: str
      }
      res = case str
      when /^(\b(u?\d*))+$/
        solr.get('/solr/authors/number') do |req|
          req.params.merge!(p)
        end
      when /^(\b\w*(\.|@)\w*)+$/
        solr.get('/solr/authors/email') do |req|
          req.params.merge!(p)
        end
      when /^(\b[a-zA-z]+,?\s*)+$/
        solr.get('/solr/authors/name') do |req|
          req.params.merge!(p)
        end
      else
        solr.get('/solr/authors/any') do |req|
          p[:q] = p[:q].gsub(".", "*")
          req.params.merge!(p)
        end
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
