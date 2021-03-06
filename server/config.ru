# frozen_string_literal: true

require 'uri'
require 'json'
require 'roda'
require 'faraday'
require 'httpx/adapters/faraday'
require 'awesome_print'
require 'digest'

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

class App < Roda

  opts[:add_script_name] = 'covoc'
  plugin :json
  plugin :typecast_params
  plugin :public
  plugin :type_routing, types: {
    xml: 'application/xml'
  }

  NO_RESULT = { numFound: 0, start: 0, docs: [] }

  solr_host = ENV['SOLR_HOST'] || 'http://localhost:8983'
  limo_host = ENV['LIMO_HOST'] || 'limo.libis.be'
  lirias_host = ENV['LIRIAS_HOST'] || 'https://lirias2repo.kuleuven.be'
  logging = ENV['LOG_LEVEL'] == 'debug'

  solr = Faraday.new(solr_host, params: {indent: false}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.request :json
    f.response :json
    f.response :logger, nil, {headers: true, bodies: false} if logging
    f.adapter :httpx
  end

  limo = Faraday.new('https://services.libis.be', params: {host: limo_host, institution: 'lirias', sort: 'scdate'}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.request :json
    f.response :json
    f.response :logger, nil, {headers: true, bodies: false} if logging
    f.adapter :httpx
  end

  lirias = Faraday.new(lirias_host, ssl: {verify: false}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.response :logger, nil, {headers: true, bodies: false} if logging
    f.adapter :httpx
  end

  sha256 = Digest::SHA256.new

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

      # Pass the Lirias host to the client
      res['lirias'] = lirias_host

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
      return NO_RESULT unless str

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
          url = [data.dig('links', 'backlink')].flatten.last
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
            link: url
          }.tap do |x|
            x[:doi] = doi if doi
            x[:issn] = issn if issn
            x[:url] = "https://doi.org/#{doi}" if doi
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

    # Entrypoint for the citation lookup
    r.get 'citation' do

      # Get parameters
      id = typecast_params.str('id')
      next unless id

      # Query Lirias reporting database for citation
      res = lirias.get('/reports/report/publicationAPA', nil, ) do |req|
        req.headers[:content_type] = 'application/xml'
        req.params['Pub_ID'] = id
        req.params['Direct'] = nil
        req.options.timeout = 2
      end

      # Check response status
      case res.status
      when 503
        # Temporary error
        response.status = 503
        { citation: '', error: 'Database in use', status: 503 }
      when 200
        if res.body =~ /<citation>(.*)<\/citation>/
          # Return the citation
          response.status = 200
          { citation: $1, status: 200 }
        else
          response.status = 404
          { citation: '', error: 'Data not found', status: 404 }
        end
      else
        response.status = res.status
        { citation: '', status: res.status }
      end
      
    end


    # Entrypoint for claimer
    r.post 'claimer' do
      res = { status: "OK" }
    
      # read the r.body stream
      content = r.body.read
      # Write the content in a file for Lirias import
      begin
        File.open("/data/json/#{sha256.hexdigest content}.json", 'w') { |file| file.write(content) }
      rescue => exception
        res = { status: "failed", error: exception }
      end
        
      # Finally, return the response
      res
        
    end

    # Entrypoint for openAIRE
    r.get 'openaire/search/datasets' do
      r.xml do
        res = OpenAire.search('/datasets') do |req|
          req.params = r.params
          req.options.timeout = 2
        end
        res.body
      end
    end

  end

end

run App.freeze.app
