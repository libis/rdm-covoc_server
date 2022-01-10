require 'csv'
require 'json'

class Array
  def row2hash(row)
    self <<
    { 
      id: row['Username'],
      uNumber: row['Username'],
      firstName: [row['Firstname'], row['KnownAs']].uniq,
      lastName: row['Lastname'],
      eMail: row['Email'],
      affiliation: 'KU Leuven',
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

File.open('data.json', 'wt') do |out|
  File.open(ARGV[0], 'rt') do |file|
    out.puts(CSV.parse(file, **options).reduce([], :row2hash).to_json)
  end
end
