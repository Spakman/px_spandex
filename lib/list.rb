# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

# A class for handling circular lists for use in Honcho talking applications.
class List
  def initialize(items)
    @items = items
    @selected_index = 0
  end

  def selected
    @items[@selected_index]
  end

  def select_next
    if @selected_index < @items.length - 1
      @selected_index += 1
    else
      @selected_index = 0
    end
    @items[@selected_index]
  end

  def select_previous
    if @selected_index > 0
      @selected_index -= 1
    else
      @selected_index = @items.length - 1
    end
    @items[@selected_index]
  end

  def to_s
    list = "<list>\n"
    @items.each do |item|
      list << "  <item"
      list << ' selected="yes"' if item == @items[@selected_index]
      list << ">#{item}</item>\n"
    end
    list << "</list>\n"
  end
end
