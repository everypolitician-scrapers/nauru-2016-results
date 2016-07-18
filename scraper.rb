#!/bin/env ruby
# encoding: utf-8

require 'colorize'
require 'nokogiri'
require 'open-uri'
require 'scraperwiki'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

class Polidata

  class Page

    def initialize(url)
      @url = url
    end

    def as_data
      @md ||= Hash[ protected_methods.map { |m| [m, send(m)] } ]
    end

    private

    def noko
      @noko ||= Nokogiri::HTML(open(@url).read)
    end

  end

end

class NauruGov

  class ElectionResults < Polidata::Page

    protected

    def results
      triples = results_box[results_box.find_index('Yaren') .. -2]
      triples.each_slice(3).map do |area, winners, _|
        {
          area: area,
          winners: parse_winners(winners),
        }
      end
    end


    private

    def results_box
      # I can't get the regexp right here to split on \n\s+\n, so this
      # will have to do for now
      @_results ||= noko.css('.articleContent p').text.gsub(/\n\s+/m, '----EO----').split('----EO----').map(&:tidy)
    end

    def parse_winners(str)
      str.split(/(?:, | and )/).map { |s|
        s.reverse.split(/\s+/,2).reverse.map(&:reverse)
      }.map { |name, votes| { name: name, votes: votes.sub(/\.$/,'') } }
    end

  end
end

source = 'http://www.naurugov.nr/government-information-office/media-release/elected-members-for-nauru-elections-2016-(1).aspx'
data = NauruGov::ElectionResults.new(source).as_data[:results].map do |r|
  r[:winners].map do |w|
    w.merge(area: r[:area])
  end
end.flatten

warn data
ScraperWiki.save_sqlite([:name, :area], data)

