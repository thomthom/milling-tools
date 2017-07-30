#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

require 'tt_milling/utils/object_info'


module TT::Plugins::MillingTools

  class Shape

    include ObjectInfo

    attr_accessor :outer_loop, :holes, :thickness

    def initialize(outer_loop, thickness)
      @thickness = thickness.to_l
      @outer_loop = outer_loop
      @holes = []
    end

    def add_hole(loop)
      @holes << loop
    end

    def to_s
      inspect
    end

    def inspect
      object_info(" #{@thickness}, #{@outer_loop.size} points, #{@holes.size} holes")
    end

  end # class

end # module
