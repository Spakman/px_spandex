# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

module Spandex
  # A simple key/value based cache that can be limited by a maximum numbe
  # of items.
  class Cache
    def initialize(max_items = nil)
      @cache = {}
      @max_items = max_items
    end

    # Tries to fetch an item from the cache based on the index. So that we
    # expire items that were accessed least recently when the cache is full,
    # this operation is actually an expire and a put.
    def get(index)
      item = expire index
      put index, item
    end

    def put(index, value)
      expire_oldest_if_full
      @cache[index] = value
    end

    def expire(index)
      @cache.delete index
    end

    def expire_oldest_if_full
      if @max_items and @cache.size == @max_items
        expire @cache.keys.first
      end
    end

    alias_method :remove, :expire
    alias_method :delete, :expire
    alias_method :[], :get
    alias_method :[]=, :put
  end
end
