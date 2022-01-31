require 'csv'
require 'json'

class Array
  def row2hash(row)
    self <<
    { 
      id: row['Username'],
      uNumber: row['Username'],
      firstName: row['KnownAs'],
      lastName: row['Lastname'],
      fullName: "#{row['Lastname']}, #{row['KnownAs']}",
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

File.open(ARGV[1], 'wt') do |out|
  File.open(ARGV[0], 'rt') do |file|
    out.puts(CSV.parse(file, **options).reduce([], :row2hash).to_json)
  end
end
