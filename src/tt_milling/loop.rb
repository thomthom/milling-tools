#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

require 'tt_milling/utils/object_info'


module TT::Plugins::MillingTools

  class Loop

    Arc = Struct.new(:center, :xaxis, :normal, :radius, :start_angle, :end_angle, :num_segments)

    include ObjectInfo

    attr_accessor :edges, :arcs

    def initialize
      @edges = []
      @arcs = []
    end

    def add_edge(point1, point2)
      @edges << [point1, point2]
    end

    def add_arc(center, xaxis, normal, radius, start_angle, end_angle, num_segments)
      @arcs << Arc.new(center, xaxis, normal, radius, start_angle, end_angle, num_segments)
    end

    def to_s
      inspect
    end

    def inspect
      object_info(" #{@thickness}, #{@points.size} points, #{@holes.size} holes")
    end

  end # class

end # module
