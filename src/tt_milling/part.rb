#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

require 'tt_milling/utils/object_info'


module TT::Plugins::MillingTools

  class Part

    include ObjectInfo

    attr_reader :shapes, :transformation

    def initialize(shapes, transformation)
      @shapes = shapes
      @transformation = transformation
    end

    def to_s
      inspect
    end

    def inspect
      object_info(" #{@shapes.size} shapes")
    end

  end # class

end # module
