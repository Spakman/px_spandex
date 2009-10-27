# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require "rufus/tokyo"

module Messier
  class Model
    @@table = Rufus::Tokyo::Table.new(TABLE_FILEPATH, :mode => 'r')

    def hash
      @name.hash
    end

    def eql?(object)
      hash == object.hash
    end

    def self.close_table
      @@table.close
    end

    def self.open_table
      @@table = Rufus::Tokyo::Table.new(TABLE_FILEPATH, :mode => 'r')
    end

    def ==(object)
      eql? object
    end

    def <=>(object)
      name <=> object.name
    end

    def self.all
      results = []
      column_name = self.to_s.downcase
      rows = @@table.query do |query|
        query.order_by column_name
      end
      rows.each do |row|
        results << self.new(row)
      end
      results.sort.uniq
    end
  end
end
