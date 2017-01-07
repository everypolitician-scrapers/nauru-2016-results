#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class ResultsPage < Scraped::HTML
  field :results do
    triples = results_box[results_box.find_index('Yaren')..-2]
    triples.each_slice(3).map do |area, winners, _|
      {
        area:    area,
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
    str.split(/(?:, | and )/).map do |s|
      s.reverse.split(/\s+/, 2).reverse.map(&:reverse)
    end.map { |name, votes| { name: name, votes: votes.sub(/\.$/, '') } }
  end
end

source = 'http://www.naurugov.nr/government-information-office/media-release/elected-members-for-nauru-elections-2016-(1).aspx'
data = ResultsPage.new(response: Scraped::Request.new(url: source).response).results.map do |r|
  r[:winners].map do |w|
    w.merge(area: r[:area])
  end
end.flatten

# puts data
ScraperWiki.save_sqlite(%i(name area), data)
