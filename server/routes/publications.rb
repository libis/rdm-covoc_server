# frozen_string_literal: true

require 'faraday'
require 'httpx/adapters/faraday'

require './lib/symbol_extensions'

class App

  using SymbolExtensions

  logging = ENV['LOG_LEVEL'] == 'debug'
  limo_token = ENV['LIMO_TOKEN']

  limo = Faraday.new('https://services.libis.be/search/lirias', params: {token: limo_token}) do |f|
    f.use Faraday::Request::UrlEncoded
    f.request :json
    f.response :json
    f.response :logger, nil, {headers: true, bodies: false} if logging
    f.adapter :httpx
  end

  # Entrypoint for Publications search
  hash_branch 'publications' do |r|

    r.get do

      min_from = 1
      min_page = 1
      default_from = 1
      default_page = 10

      # Get parameters
      str = typecast_params.str('q')
      return NO_RESULT unless str

      from = [min_from, typecast_params.int('from') || default_from].max
      per_page = [min_page, typecast_params.int('per_page') || default_page].max

      # Perform Limo search
      p = {
        from: from,
        bulksize: per_page
      }
      res = case str
      when /^\d+$/
        limo.get do |req|
          req.params.merge!(p)[:query] = "any:lirias#{str}"
        end
      when /^u\d+$/
        limo.get do |req|
          req.params.merge!(p)[:query] = "creator:#{str}"
        end
      when /^@/
        limo.get do |req|
          req.params.merge!(p)[:query] = "creator:#{str[1..-1]}"
        end
      else
        limo.get do |req|
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
        'numFound' => res.dig('info', 'total').to_i,
        'start' => res.dig('info', 'first').to_i,
        'docs' => res['docs'].map do |data|
          creator = [data.dig('pnx', 'addata', 'au')].flatten.join('; ')
          title = [data.dig('pnx', 'addata', 'title')].flatten.first
          ispartof = [data.dig('pnx', 'display', 'ispartof')].flatten.first
          url = [data.dig('pnx', 'links', 'backlink')].flatten.map(&:[].(/\$\$U([^\$]*)/, 1)).last
          doi = [data.dig('pnx', 'addata', 'doi')].flatten.first
          issn = nil
          id = nil
          [data.dig('pnx', 'control', 'recordid')].flatten.each do |src_id|
            next if id
            if src_id =~ /^LIRIAS(\d+)$/i
              id = $1
            end
          end
          {
            id: id,
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
  end
end
