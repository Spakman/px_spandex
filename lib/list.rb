# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

# A class for handling circular lists for use in Honcho talking applications.
class List
  NUMBER_OF_LIST_ITEMS_TO_DISPLAY = 5

  def initialize(items)
    @items = items
    @selected_index = 0
    @starting_item = 0
  end

  def selected
    @items[@selected_index]
  end

  def select_next
    if @selected_index < @items.length - 1
      if @selected_index >= @starting_item + NUMBER_OF_LIST_ITEMS_TO_DISPLAY - 1
        @starting_item += 1
      end
      @selected_index += 1
    end
    @items[@selected_index]
  end

  def select_previous
    if @selected_index > 0
      @selected_index -= 1
      if @starting_item > 0 and @starting_item == @selected_index + 1
        @starting_item -= 1
      end
    end
    @items[@selected_index]
  end

  def selected_to_end
    @items[@selected_index..@items.length-1]
  end

  def to_s
#   puts "starting at #{@starting_item} (#{@items[@starting_item]})   and selected #{@selected_index} (#{@items[@selected_index]})"
    list = "<list>\n"
    @items[@starting_item...@starting_item+NUMBER_OF_LIST_ITEMS_TO_DISPLAY].each do |item|
      list << "  <item"
      list << ' selected="yes"' if item == @items[@selected_index]
      list << ">#{item}</item>\n"
    end
    list << "</list>\n"
  end
end
