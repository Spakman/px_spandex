# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require "#{File.dirname(__FILE__)}/../lib/model"
require "#{File.dirname(__FILE__)}/../lib/track"
require "#{File.dirname(__FILE__)}/../lib/album"

class Genre < Model
  attr_reader :name

  def initialize(row)
    @name = row['genre']
    @query = @@table.prepare_query
    @query.add_condition 'genre', :equals, @name
  end

  def hash
    @name.hash
  end

  def albums
    albums = []
    @query.order_by 'album'
    @query.run.each do |row|
      albums << Album.new(row)
    end
    albums.uniq
  end
end
