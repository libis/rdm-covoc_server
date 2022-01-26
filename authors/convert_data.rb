require 'csv'
require 'json'
require 'progress_bar'

class CSV
  module ProgressBar
    def progress_bar
      ::ProgressBar.new(@io.size, :bar, :percentage, :elapsed, :eta)
    end

    def each
      progress_bar = self.progress_bar

      super do |row|
        yield row
        progress_bar.count = self.pos
        progress_bar.increment!(0)
      end
    end
  end

  class WithProgressBar < CSV
    include ProgressBar
  end

  def self.with_progress_bar
    WithProgressBar
  end
end

class Array
  def row2hash(row)

    self <<
    { 
      id: row['Username'],
      uNumber: row['Username'],
      firstName: row['Firstname'],
      lastName: row['Lastname'],
      fullName: "#{row['Lastname']}, #{row['Firstname']}",
      eMail: row['Email'],
      affiliation: 'Associatie KU Leuven',
      orcid: row['Generic15']
    }
  end
end

header_converter = proc { |name| name.length > 2 ? name[1...-1] : name }

options = {
  headers: true,
  col_sep: ',',
  quote_char: '"',
  header_converters: header_converter,
  skip_blanks: true
}

line_count = `wc -l "#{ARGV[0]}"`.strip.split(' ')[0].to_i - 1

File.open(ARGV[1], 'wt') do |out|
  File.open(ARGV[0], 'rt') do |file|
    out.puts(CSV::WithProgressBar.parse(file, **options).reduce([], :row2hash).to_json)
  end
end
