#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

require 'tt_milling/utils/geom'
require 'tt_milling/utils/instance'
require 'tt_milling/part'
require 'tt_milling/shape'


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


  def self.collect_parts(entities)
    instances = entities.select { |entity| self.is_instance?(entity) }
    definitions = instances.map { |instance| self.definition(instance) }.uniq
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


  def self.generate_part(part, x, y)
    model = Sketchup.active_model
    entities = model.active_entities
    group = entities.add_group
    tr = Geom::Transformation.new([x, y, 0])
    part.each { |shape|
      # Boundary
      points = shape.points.map { |point| point.transform(tr) }
      face = group.entities.add_face(points)
      face.reverse! unless face.normal.samedirection?(Z_AXIS)
      # Holes
      holes = shape.holes.map { |hole|
        points = hole.map { |point| point.transform(tr) }
        group.entities.add_face(points)
      }
      group.entities.erase_entities(holes)
    }
    group
  end



end # module
