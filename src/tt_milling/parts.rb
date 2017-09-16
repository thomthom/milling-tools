#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

require 'set'

require 'tt_milling/utils/geom'
require 'tt_milling/utils/instance'
require 'tt_milling/utils/transformation'
require 'tt_milling/utils/walker'
require 'tt_milling/loop'
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

    begin
      model.start_operation('Generate Cut Parts', true)
      parts.each { |part|
        instance = self.generate_part_instance(part, x, y)
        y += instance.bounds.height + 20.mm
      }
    ensure
      model.commit_operation
    end
  end


  def self.extract_scaling(transformation)
    transformation.extend(TransformationHelper)
    sx, sy, sz = transformation.scales
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
    boundary = self.extract_loop(face.outer_loop)
    shape = Shape.new(boundary, thickness)
    face.loops.each { |loop|
      next if loop.outer?
      hole = self.extract_loop(loop)
      shape.add_hole(hole)
    }
    shape
  end

  def self.extract_loop(face_loop)
    processed = Set.new
    loop = Loop.new
    face_loop.edges.each { |edge|
      next if processed.include?(edge)
      curve = edge.curve
      if self.is_arc?(curve)
        loop.add_arc(curve.center, curve.xaxis, curve.normal, curve.radius,
                     curve.start_angle, curve.end_angle, curve.edges.size)
        processed.merge(edge.curve.edges)
      else
        loop.add_edge(edge.start.position, edge.end.position)
        processed << edge
      end
    }
    loop
  end


  def self.is_arc?(curve)
    return false if curve.nil?
    return false unless curve.is_a?(Sketchup::ArcCurve)
    !curve.is_polygon?
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
      face = self.face_from_loop(definition.entities, shape.outer_loop)
      face.reverse! unless face.nil? || face.normal.samedirection?(Z_AXIS)
      # Holes
      holes = shape.holes.map { |hole|
        self.face_from_loop(definition.entities, hole)
      }
      definition.entities.erase_entities(holes)
    }
    # Adjust position
    definition.entities.transform_entities(part.transformation,
                                           definition.entities.to_a)
    # Adjust the instance to the bounds of the entities.
    origin = definition.bounds.min
    tr_origin = Geom::Transformation.new(origin).inverse
    transformation = tr_origin * tr
    instance = entities.add_instance(definition, transformation)
    instance
  end


  def self.trace(*args)
    puts(*args) if false
  end


  class FaceCreateError < RuntimeError; end
  # @param [Boolean] create_face debug parameter to control whether the face is
  #   actually created.
  def self.face_from_loop(entities, loop, create_face = true)
    trace
    trace '=' * 20
    trace "face_from_loop (debug = #{create_face})"
    trace "  Faces 01: #{entities.grep(Sketchup::Face).size}"
    # Cache the existing faces and edges. This is used later on to determine
    # exactly what new entities we generate. The return values are not reliable.
    existing_edges = entities.grep(Sketchup::Edge)
    existing_faces = entities.grep(Sketchup::Face)
    # This is the set of new edges generates.
    edges = []
    # First create the edges from straight segments.
    loop.edges.each { |points|
      trace "Points: #{points.inspect}"
      edges << entities.add_line(*points)
    }
    trace "  Faces 02: #{entities.grep(Sketchup::Face).size}"
    # Then the edges from arcs and circles.
    loop.arcs.each { |arc|
      trace "Arc: #{arc.inspect}"
      arc_edges = entities.add_arc(arc.center, arc.xaxis, arc.normal, arc.radius,
                                   arc.start_angle, arc.end_angle,
                                   arc.num_segments)
      edges.concat(arc_edges)
    }
    trace "  Faces 03: #{entities.grep(Sketchup::Face).size}"
    # Adding arcs/circles might split the face and create a new face already.
    # If we do then .add_face later on will return nil.
    new_faces = entities.grep(Sketchup::Face) - existing_faces
    if new_faces.size > 1
      # Not sure how to handle any potential edge case of generating multiple
      # new faces. Would this think would only happen with some really strange
      # intersecting loops.
      raise FaceCreateError, "created too many faces (#{new_faces.size}), unable to proceed"
    end
    # If we already created a face then there is no need to proceed.
    return new_faces.first unless new_faces.empty?
    # If we didn't create a new face already then try to manually create it
    # from the looping edges. This is the typical scenario unless the hole
    # is a circle.
    # Clean up stray edges after potential edge intersection merges.
    stray_edges = entities.grep(Sketchup::Edge).select { |edge|
      edge.vertices.any? { |vertex|
        vertex.edges.size < 2
      }
    }
    entities.erase_entities(stray_edges) unless stray_edges.empty?
    # Find the new edges from the newly created loop.
    edges = entities.grep(Sketchup::Edge) - existing_edges
    # SketchUp will sort the edges and generate a face from them.
    face = create_face ? entities.add_face(edges) : nil
    trace "  Faces 04: #{entities.grep(Sketchup::Face).size}"
    if create_face && face.nil?
      raise FaceCreateError, "failed to create face from edges"
    end
    face
  end

end # module
