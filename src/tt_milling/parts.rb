#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools

  def self.generate_parts
    model = Sketchup.active_model
    entities = model.selection.empty? ? model.active_entities : model.selection

    x = model.bounds.width + 100.mm
    y = 0

    parts = self.collect_parts(entities)
    # puts parts.join("\n")
    parts.each { |part| p part }

    model.start_operation('Generate Cut Parts', true)
    parts.each { |part|
      # p part
      instance = self.generate_part(part, x, y)
      y += instance.bounds.height + 20.mm
    }
    model.commit_operation
  end


  def self.generate_part(part, x, y)
    model = Sketchup.active_model
    entities = model.active_entities
    group = entities.add_group
    tr = Geom::Transformation.new([x, y, 0])
    part.each { |shape|
      points = shape.points.map { |point| point.transform(tr) }
      face = group.entities.add_face(points)
      face.reverse! unless face.normal.samedirection?(Z_AXIS)

      holes = shape.holes.map { |hole|
        points = hole.map { |point| point.transform(tr) }
        group.entities.add_face(points)
      }
      group.entities.erase_entities(holes)
    }
    group
  end


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


  class Part #< Array

    include Enumerable

    def initialize(shapes)
      @shapes = shapes
    end

    def each
      @shapes.each { |shape| yield shape }
    end

    # def to_ary
    #   @shapes.dup
    # end

    def to_s
      inspect
    end

    def inspect
      items = @shapes.join(', ')
      "<#{self::class::name}:#{object_id} #{@shapes.size} shapes: [#{items}]>"
    end

  end # class


  def self.collect_parts(entities)
    instances = entities.select { |entity| self.is_instance?(entity) }
    definitions = instances.map { |instance| self.definition?(instance) }.uniq
    definitions.map { |definition| self.create_parts(definition) }.flatten
  end

  def self.create_parts(definition)
    thickness = definition.bounds.depth
    faces = definition.entities.grep(Sketchup::Face)
    faces.select! { |face| self.on_ground?(face) }
    shapes = faces.map { |face|
      points = face.outer_loop.vertices.map(&:position)
      shape = Shape.new(points, thickness)
      face.loops.each { |loop|
        next if loop.outer?
        hole = loop.vertices.map(&:position)
        shape.add_hole(hole)
      }
      shape
    }
    definition.instances.map { |_| Part.new(shapes) }.flatten
  end


  GROUND = [ORIGIN, Z_AXIS]
  def self.on_ground?(face)
    face.normal.parallel?(Z_AXIS) && face.vertices.all? { |vertex| vertex.position.on_plane?(GROUND) }
  end

  def self.is_instance?(entity)
    entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
  end

  def self.definition?(instance)
    if instance.respond_to?(:definition)
      instance.definition
    else
      # TODO:
      raise NotImplementedError
    end
  end


  def self.open_help
    UI.openURL(EXTENSION[:url])
  end

end # module
