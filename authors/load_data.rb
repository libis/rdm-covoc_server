# frozen_string_literal: true
require_relative '../lib/reader'
require_relative '../lib/indexer'

core = ARGV[1] || File.basename(File.dirname(__FILE__))
file = ARGV[0] || '.'

reader = Reader.new
reader.from_json_file(file:)

indexer = Indexer.new(core:)
indexer.add(data: reader.get_data)
