# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require_relative "model"
require_relative "album"

module Messier
  class Artist < Model
    attr_reader :name

    def initialize(row)
      @name = row['artist'] || row[:artist]
      @query = @@table.prepare_query
      @query.add_condition 'artist', :equals, @name
    end

    def self.get(name)
      new(artist: name)
    end

    def albums
      albums = []
      @query.order_by 'album'
      @query.run.each do |row|
        albums << Album.new(row)
      end
      albums.uniq
    end

    def to_s
      @name
    end
  end
end
