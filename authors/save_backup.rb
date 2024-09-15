# frozen_string_literal: true
require_relative '../lib/indexer'
require_relative '../lib/writer'

dir = ARGV[0] || '.'
FileUtils.mkdir_p(dir)
glob = File.join(dir, 'backup_*.json')

core = ARGV[1] || File.basename(File.dirname(__FILE__))

rows = ARGV[2] || 500
rows = rows.to_i

indexer = Indexer.new(core:)
writer = Writer.new
total = indexer.get_total(rows:)

bar = $stdout.tty? ? TTY::ProgressBar.new(
  "Saving backup pages (:percent)\tETA: :eta_time (:eta) [:current/:total @ :rate/s]",
  total: total
) : nil

writer.stack_files(glob:, stack_size: 3)

page = 1
while (data = indexer.get_docs(page:, rows:))
  writer.set_data(data:)
  writer.to_json(file: File.join(dir, "backup_#{"%03d" % page}.json"))
  bar&.advance(1)
  page += 1
end
bar&.finish
