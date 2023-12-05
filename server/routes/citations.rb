# frozen_string_literal: true

require 'faraday'
require 'httpx/adapters/faraday'

class App

  logging = ENV['LOG_LEVEL'] == 'debug'
  lirias_host = ENV['LIRIAS_HOST'] || 'https://lirias2repo.kuleuven.be'

  lirias = Faraday.new(lirias_host, ssl: {verify: false}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.response :logger, nil, {headers: true, bodies: false} if logging
    f.adapter :httpx
  end

  # Entrypoint for the citation lookup
  hash_branch 'citation' do |r|
    r.get do

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
  end
end
