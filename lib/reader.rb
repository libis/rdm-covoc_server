# frozen_string_literal: true
require 'csv'
require 'json'
require 'tty-progressbar'

class Reader

  attr_reader :data

  def initialize
    @data = {}
    @tty = $stdout.tty?
  end

  def get_data
    @data.values
  end

  def from_json_files(glob: nil)
    total = Dir.glob(glob).size
    bar = @tty ? TTY::ProgressBar.new(
      "Parsing files (:percent)\tETA: :eta_time (:eta) [:current/:total @ :rate/s]", total:
    ) : nil
    bar&.advance(0)
    Dir.glob(glob) do |file|
      parse_json_file(file:)
      bar&.advance(1)
    end
    bar&.finish
  end

  def from_json_file(file: nil)
    return unless File.exist?(file.to_s)
    bar = @tty ? TTY::ProgressBar.new(
      "Parsing #{File.basename(file.to_s)} [:current @ :rate/s]"
    ) : nil
    parse_json_file(file:, bar:)
  end

  def from_sap_files(glob: nil)
    total = Dir.glob(glob).size
    bar = @tty ? TTY::ProgressBar.new(
      "Parsing files (:percent)\tETA: :eta_time (:eta) [:current/:total @ :rate/s]", total:
    ) : nil
    bar&.advance(0)
    Dir.glob(glob) do |file|
      parse_sap_file(file:)
      bar&.advance(1)
    end
    bar&.finish
  end

  def from_sap_file(file: nil)
    return unless File.exist?(file.to_s)
    bar = @tty ? TTY::ProgressBar.new(
      "Parsing #{File.basename(file.to_s)} [:current @ :rate/s]"
    ) : nil
    parse_sap_file(file:, bar:)
  end

  private

  def parse_json_file(file:, bar: nil)
    JSON.load_file(file.to_s).each do |record|
      @data[record['id']] = record.compact
      bar&.advance(1)
    end
    bar&.finish
  end

  def parse_sap_file(file:, bar: nil)
    return unless File.exist?(file.to_s)
    File.open(file.to_s, 'rt') do |csv_file|
      CSV.parse(
        csv_file,
        headers: true,
        col_sep: ',',
        quote_char: '"',
        header_converters: proc { |name| name.length > 2 ? name[1...-1] : name },
        skip_blanks: true
      ).each do |record|
        next unless record['Username'] && record['KnownAs'] && record['Lastname']
        @data[record['Username']] = transform_from_sap(record)
        bar&.advance(1)
      end
    end
    bar&.finish
  end

  def transform_from_sap(record)
    {
      id: record['Username'],
      uNumber: record['Username'],
      firstName: record['KnownAs'],
      lastName: record['Lastname'],
      fullName: "#{record['Lastname']}, #{record['KnownAs']}",
      eMail: record['Email'],
      affiliation: 'Associatie KU Leuven',
      orcid: record['Generic15']
    }.compact
  end

end
