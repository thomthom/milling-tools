#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

require 'tt_milling/utils/geom'
require 'tt_milling/utils/instance'
require 'tt_milling/utils/transformation'
require 'tt_milling/utils/walker'
require 'tt_milling/part'
require 'tt_milling/shape'
require 'tt_milling/shapes'


module TT::Plugins::MillingTools

  def self.generate_parts
    model = Sketchup.active_model
    entities = model.selection.empty? ? model.active_entities : model.selection

    x = model.bounds.width + 100.mm
    y = 0

    parts = self.collect_parts(entities)
    # puts parts.join("\n")
    # parts.each { |part| p part }

    model.start_operation('Generate Cut Parts', true)
    parts.each { |part|
      # p part
      instance = self.generate_part_instance(part, x, y)
      y += instance.bounds.height + 20.mm
    }
    model.commit_operation
  end


  def self.extract_scaling(transformation)
    transformation.extend(TransformationHelper)
    sx, sy, sz = transformation.scales
    # p [sx, sy, sz]
    Geom::Transformation.scaling(sx, sy, sz)
  end


  def self.collect_parts(entities)
    parts = []
    shape_cache = {}
    self.walk_instances(entities) { |instance, transformation|
      definition = self.definition(instance)
      # Compute one of set of shapes per definition.
      shape_cache[definition] ||= self.create_shapes(definition)
      shapes = shape_cache[definition]
      next if shapes.empty?
      # Each instance have a Part counterpart.
      scaling_transformation = self.extract_scaling(transformation)
      parts << Part.new(shapes, scaling_transformation)
    }
    parts
  end


  def self.create_shapes(definition)
    thickness = definition.bounds.depth
    faces = definition.entities.grep(Sketchup::Face)
    faces.select! { |face| self.on_ground?(face) }
    shapes = faces.map { |face|
      self.create_shape(face, thickness)
    }
    Shapes.new(shapes)
  end


  def self.create_shape(face, thickness)
    # TODO: Preserve arcs and circles.
    points = face.outer_loop.vertices.map(&:position)
    shape = Shape.new(points, thickness)
    face.loops.each { |loop|
      next if loop.outer?
      hole = loop.vertices.map(&:position)
      shape.add_hole(hole)
    }
    shape
  end


  def self.generate_part_instance(part, x, y)
    model = Sketchup.active_model
    entities = model.active_entities
    tr = Geom::Transformation.new([x, y, 0])
    # TODO: Reuse definitions.
    # TODO: Update previously created parts.
    definition = model.definitions.add('Part')
    part.shapes.each { |shape|
      # Boundary
      points = shape.points.map { |point| point.transform(part.transformation) }
      face = definition.entities.add_face(points)
      face.reverse! unless face.normal.samedirection?(Z_AXIS)
      # Holes
      holes = shape.holes.map { |hole|
        points = hole.map { |point| point.transform(part.transformation) }
        definition.entities.add_face(points)
      }
      definition.entities.erase_entities(holes)
    }
    # Adjust the instance to the bounds of the entities.
    origin = definition.bounds.min
    tr_origin = Geom::Transformation.new(origin).inverse
    transformation = tr_origin * tr
    instance = entities.add_instance(definition, transformation)
    instance
  end

end # module
