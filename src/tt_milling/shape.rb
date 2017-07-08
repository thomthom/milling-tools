#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools

  class Shape

    attr_accessor :points, :holes, :thickness

    def initialize(points, thickness)
      @thickness = thickness.to_l
      @points = points
      @holes = []
    end

    def add_hole(points)
      @holes << points
    end

    def to_s
      inspect
    end

    def inspect
      "<#{self::class::name}:#{object_id} #{@thickness}, #{@points.size} points, #{@holes.size} holes>"
    end

  end # class

end # module
