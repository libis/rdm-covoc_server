# frozen_string_literal: true

require 'roda'
require 'faraday'
require 'httpx/adapters/faraday'

require './lib/open_aire.rb'

class App

  # Entrypoint for openAIRE
  hash_branch 'openaire/search/datasets' do |r|
    r.get do
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
