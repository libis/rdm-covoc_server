# frozen_string_literal: true
require_relative '../lib/reader'
require_relative '../lib/writer'

files = ARGV[0]
target = ARGV[1]
start_file = ARGV[2]

reader = Reader.new
reader.from_json_file(file: start_file) if File.exist?(start_file.to_s)
reader.from_sap_files(glob: files)

writer = Writer.new
writer.set_data(data: reader.get_data)
writer.to_json(file: target)

target_dir = File.join(File.dirname(files), 'accumulated')
writer.move_files(glob: files, target_dir:)
