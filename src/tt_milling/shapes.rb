#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

require 'tt_milling/utils/object_info'


module TT::Plugins::MillingTools

  class Shapes

    include Enumerable
    include ObjectInfo

    def initialize(shapes)
      @shapes = shapes
    end

    def each
      @shapes.each { |shape| yield shape }
    end

    def empty?
      @shapes.empty?
    end

    def size
      @shapes.size
    end

    def to_s
      inspect
    end

    def inspect
      items = @shapes.join(', ')
      object_info(" #{@shapes.size} shapes: [#{items}]")
    end

  end # class

end # module
