# frozen_string_literal: true
require 'rsolr'
require 'tty-progressbar'

class Indexer

  def initialize(core:)
    @solr = RSolr.connect url: "#{ENV['SOLR_HOST']}/solr/#{core}"
    @tty = $stdout.tty?
  end

  def add(data:, per_page: 100)
    bar = @tty ? TTY::ProgressBar.new(
      "Indexing data (:percent)\tETA: :eta_time (:eta) [:current/:total @ :rate/s]",
      total: data.size
    ) : nil
    bar&.advance(0)
    data.each_slice(per_page) do |slice|
      update(docs: slice)
      bar&.advance(per_page)
    end
    bar&.finish
  end

  def get_docs(page:, rows:)
    response = @solr.paginate page, rows, 'select', params: {q: '*:*'}

    unless response.response[:status] == 200
      puts "Error: #{response.response[:body].inspect}"
      return []
    end
    docscount = response['response']['docs'].size
    return nil if docscount == 0
    docs = response['response']['docs']
    docs.each {|x| x.delete('_version_')}
    docs
  end

  def get_total(rows:)
    response = @solr.paginate 0, 0, 'select', params: {q: '*:*'}

    unless response.response[:status] == 200
      puts "Error: #{response.response[:body].inspect}"
      return 0
    end
    (1.0 * response['response']['numFound'] / rows).ceil
  end

  private

  def update(docs:)
    response = @solr.add(docs)
    unless response.response[:status] == 200
      puts "Error: #{response.response[:body].inspect}"
    end
    @solr.commit
  end

end
