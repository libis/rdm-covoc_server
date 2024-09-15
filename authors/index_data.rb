# frozen_string_literal: true
require_relative '../lib/reader'
require_relative '../lib/indexer'

file = ARGV[0]
core = ARGV[1] || File.basename(File.dirname(__FILE__))

reader = Reader.new
reader.from_sap_file(file:)

indexer = Indexer.new(core:)
indexer.add(data: reader.get_data)
