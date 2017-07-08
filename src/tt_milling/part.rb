#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools

  class Part

    include Enumerable

    def initialize(shapes)
      @shapes = shapes
    end

    def each
      @shapes.each { |shape| yield shape }
    end

    def to_s
      inspect
    end

    def inspect
      items = @shapes.join(', ')
      "<#{self::class::name}:#{object_id} #{@shapes.size} shapes: [#{items}]>"
    end

  end # class

end # module
