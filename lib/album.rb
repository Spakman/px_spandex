# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require_relative "model"
require_relative "artist"
require_relative "track"

module Messier
  class Album < Model
    attr_reader :name, :artist

    def initialize(row)
      @name = row['album']
      @artist = Artist.new row
      @query = @@table.prepare_query
      @query.add_condition 'album', :equals, @name
      @query.add_condition 'artist', :equals, @artist.name
    end

    def hash
      (@name + @artist.name).hash
    end

    def tracks
      tracks = []
      @query.order_by 'track_nr'
      @query.run.each do |row|
        tracks << Track.new(row)
      end
      tracks.uniq
    end

    def to_s
      @name
    end
  end
end
