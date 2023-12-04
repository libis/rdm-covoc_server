# frozen_string_literal: true

require 'uri'
require 'json'
require 'roda'


class App < Roda

  opts[:add_script_name] = 'covoc'
  plugin :json
  plugin :typecast_params
  plugin :public
  plugin :hash_branches
  plugin :heartbeat
  plugin :type_routing, types: {
    xml: 'application/xml'
  }

  NO_RESULT = { numFound: 0, start: 0, docs: [] }

  Dir["routes/**/*.rb"].each do |route_file|
    require_relative route_file
  end

  route do |r|
    # Static content (covoc.js)
    r.public

    r.hash_branches
  end

end
