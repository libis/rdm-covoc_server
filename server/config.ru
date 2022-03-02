# frozen_string_literal: true

require 'uri'
require 'json'
require 'roda'
require 'faraday'
require 'httpx/adapters/faraday'
require 'awesome_print'

class App < Roda

  opts[:add_script_name] = 'covoc'
  plugin :json
  plugin :typecast_params
  plugin :public

  NO_RESULT = { numFound: 0, start: 0, docs: [] }

  solr_host = ENV['SOLR_HOST'] || 'http://localhost:8983'
  limo_host = ENV['LIMO_HOST'] || 'limo.libis.be'
  log_level = ENV['LOG_LEVEL'] || 'error'

  solr = Faraday.new(solr_host, params: {indent: false}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.request :json
    f.response :json
    f.response :logger, nil, {headers: true, bodies: false, log_level: log_level}
    f.adapter :httpx
  end

  limo = Faraday.new('https://services.libis.be', params: {host: limo_host, institution: 'lirias', sort: 'scdate'}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.request :json
    f.response :json
    f.response :logger, nil, {headers: true, bodies: false, log_level: log_level}
    f.adapter :httpx
  end

  route do |r|

    # Static content (covoc.js)
    r.public

    # Entrypoint for Authors search
    r.get 'authors' do

      min_from = 0
      min_page = 1
      default_from = 0
      default_page = 10

      # Get parameters
      str = typecast_params.str('q')
      next unless str

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
      when /^(\b[a-zA-z]+,?)+$/
        solr.get('/solr/authors/name') do |req|
          req.params.merge!(p)
        end
      else
        solr.get('/solr/authors/any') do |req|
          req.params.merge!(p)
        end
      end

      # Check response error
      unless res&.success?
        Logger($stdout).new.error("Solr response [#{res&.status}] #{res&.headers}")
        return NO_RESULT
      end

      # Parse JSON result 
      res = JSON.parse(res.body)&.dig('response')
      return NO_RESULT unless res

      # Set start, next and previous values
      next_start = res['start'] + per_page
      prev_start = [min_from, res['start'] - per_page].max
      res['next'] = next_start if next_start < res['numFound'] + min_from
      res['prev'] = prev_start if res['start'] != min_from

      # Finally, return the response
      res

    end

    # Entrypoint for Publications search
    r.get 'publications' do

      min_from = 1
      min_page = 1
      default_from = 1
      default_page = 1

      # Get parameters
      str = typecast_params.str('q')
      next unless str

      from = [min_from, typecast_params.int('from') || default_from].max
      per_page = [min_page, typecast_params.int('per_page') || default_page].max

      # Perform Limo search
      p = {
        from: from,
        step: per_page
      }
      res = case str
      when /^\d+$/
        limo.get('/search') do |req|
          req.params.merge!(p)[:query] = "any:LIRIAS#{str}"
        end
      when /^u\d+$/
        limo.get('/search') do |req|
          req.params.merge!(p)[:query] = "user:#{str}"
        end
      when /^@/
        limo.get('/search') do |req|
          req.params.merge!(p)[:query] = "author:#{str[1..-1]}"
        end
      else
        limo.get('/search') do |req|
          req.params.merge!(p)[:query] = "any:#{str}"
        end
      end

      # Check response error
      unless res.success?
        Logger($stdout).new.error("Limo response [#{res.status}] #{res.headers}")
        return NO_RESULT
      end

      # Build the response data
      res = res.body
      res = {
        'numFound' => res['count'],
        'start' => res['from'],
        'docs' => res['data'].map do |data|
          # Can't trust output to be single value
          creator = [data.dig('display','creator')].flatten.first
          title = [data.dig('display','title')].flatten.first
          ispartof = [data.dig('display','ispartof')].flatten.first
          url = [data.dig('links', 'backlink')].flatten.first
          doi = nil
          issn = nil
          [data.dig('display','identifier')].flatten.each do |identifier|
            next unless identifier
            doi ||= identifier.scan(/\$\$CDOI:\$\$V([^$]*)/)&.first&.first
            issn ||= identifier.scan(/\$\$CISSN:\$\$V([^$]*)/)&.first&.first
           end
          {
            id: data.dig('id')&.gsub(/^LIRIAS/i, ''),
            title: title,
            citation: "#{creator}. &quot;#{title}.&quot; #{ispartof}",
            url: url
          }.tap do |x|
            x[:doi] = doi if doi
            x[:issn] = issn if issn
          end
        end
      }

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

run App.freeze.app
