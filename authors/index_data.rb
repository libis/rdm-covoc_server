# frozen_string_literal: true
require 'csv'
require 'json'
require 'tty-progressbar'
require 'tty-spinner'
require 'rsolr'
# require 'faraday'
# require 'httpx/adapters/faraday'

class CSV
  module ProgressBar
    attr_accessor :progressbar

    def progressbar
      return @progress_bar ||= TTY::ProgressBar.new("Reading data (:percent)\tETA: :eta_time (:eta)\t[:current_byte/:total_byte @ :byte_rate/s]", total: @io.size)
    end

    def each

      super do |row|
        yield row
        progressbar.current = self.pos
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

class Indexer

  attr_reader :solr, :progressbar

  def initialize(host, core)
    @solr = RSolr.connect url: "#{host}/solr/#{core}"
  end

  def self.transform(data)
    {
      id: data['Username'],
      uNumber: data['Username'],
      firstName: data['KnownAs'],
      lastName: data['Lastname'],
      fullName: "#{data['Lastname']}, #{data['KnownAs']}",
      eMail: data['Email'],
      affiliation: 'Associatie KU Leuven',
      orcid: data['Generic15']
    }
  end

  def update(data)
    response = solr.add(data)
    unless response.response[:status] == 200
      puts "Error: #{response.response[:body].inspect}"
    end
  end
end

options = {
  headers: true,
  col_sep: ',',
  quote_char: '"',
  header_converters: proc { |name| name.length > 2 ? name[1...-1] : name },
  skip_blanks: true
}

core = ARGV[1] || File.basename(File.dirname(__FILE__))

File.open(ARGV[0], 'rt') do |file|
  a = CSV::WithProgressBar.parse(file, **options)
  bar = TTY::ProgressBar.new("Formatting   (:percent)\tETA: :eta_time (:eta)\t[:current/:total @ :rate/s]", total: a.size)
  a = a.reduce([]) do |memo, data|
    memo << Indexer.transform(data)
    bar.advance
    memo
  end
  bar.complete
  bar = TTY::ProgressBar.new("Indexing     (:percent)\tETA: :eta_time (:eta)\t[:current/:total @ :rate/s]", total: a.size)
  indexer = Indexer.new(ENV['SOLR_HOST'], core)
  bar.advance(0)
  a.each_slice(100) do |slice|
    indexer.update(slice)
    bar.advance(100)
  end
end
