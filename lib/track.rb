# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require "#{File.dirname(__FILE__)}/../lib/model"
require "#{File.dirname(__FILE__)}/../lib/artist"
require "#{File.dirname(__FILE__)}/../lib/genre"

module Messier
  class Track < Model
    attr_reader :name, :album, :artist, :genre

    def initialize(row)
      @name = row['track']
      @album = Album.new row
      @artist = Artist.new row
      @genre = Genre.new row
      @query = @@table.prepare_query
      @query.add_condition 'track', :equals, @name
      @query.add_condition 'album', :equals, @album.name
      @query.add_condition 'artist', :equals, @artist.name
    end

    def hash
      (@name + @album.name + @artist.name).hash
    end

    def to_s
      @name
    end
  end
end
