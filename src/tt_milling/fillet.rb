#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools

  # Compatibility (TODO: Remove)
  PLUGIN_ID = EXTENSION[:product_id]
  PLUGIN = self

  def self.dog_bone
    Sketchup.active_model.select_tool( Dog_Bone.new )
  end


  def self.cot(radians)
    return 1.0 / Math.tan(radians)
  end

  def self.sec(radians)
    return 1.0 / Math.cos(radians)
  end

  def self.csc(radians)
    return 1.0 / Math.sin(radians)
  end


  class Dog_Bone

    def activate
      @cursor_point	  = Sketchup::InputPoint.new
      @entity = nil
      @tool_size = 5.mm
      @segments = 24

      @drawn = false

      updateVCB
    end

    def resume(view)
      updateVCB
    end

    def deactivate(view)
      view.invalidate if @drawn
    end

    def enableVCB?
      return true
    end

    def onUserText(text, view)
      if text.downcase[-1,1] == 's'
        @segments = text.chop.to_i
      else
        @tool_size = text.to_l
      end
      updateVCB
      view.invalidate
    end

    def updateVCB
      Sketchup.set_status_text("Tool size: #{@tool_size} - Circle Segments: #{@segments}", SB_PROMPT)
      Sketchup.set_status_text('Tool size:', SB_VCB_LABEL)
      Sketchup.set_status_text(@tool_size, SB_VCB_VALUE)
    end

    def onMouseMove(flags, x, y, view)
      #ph = view.pick_helper
      #ph.do_pick(x, y)

      #@face = ph.picked_face if ph.picked_face != @face
      #@edge = ph.picked_edge if ph.picked_edge != @edge
      #@best = ph.best_picked if ph.best_picked != @best

      if @cursor_point.pick(view, x, y)
        view.invalidate
      end
    end


    def onLButtonUp(flags, x, y, view)
      @cursor_point.pick(view, x, y)
      return if @cursor_point.face.nil?

      face = @cursor_point.face
      loops = fillets(face)
      model = Sketchup.active_model
      entities = model.active_entities

      PLUGIN.start_operation('Dog-Bone Fillets')

      loops.each { |loop|
        tool_path = []
        fillet_corners = []
        loop.each { |corner|
          command, vertex, tool_position, tool_offset, tool_fillet, dog_bone_points, existing_fillet = corner
          # Draw Corner
          unless tool_offset.nil?
            if existing_fillet
              curve = vertex.edges.first.curve
              curve.move_vertices(dog_bone_points)
            else
              position = vertex.position

              temp_face = entities.add_face(position, dog_bone_points.first, dog_bone_points.last)
              temp_edges = temp_face.edges

              entities.erase_entities(vertex.edges)

              curve_edges = entities.add_curve(dog_bone_points)
              curve = curve_edges.first.curve
              curve.set_attribute(PLUGIN_ID, 'Type', 'Dog-Bone')

              temp_edge = temp_edges.select { |edge| edge.valid? }
              entities.erase_entities(temp_edge)
            end
          end
        }
      }

      model.commit_operation
    end


    def draw(view)
      return if @cursor_point.face.nil?

      face = @cursor_point.face
      loops = fillets(face)

      loops.each { |loop|
        tool_path = []
        fillet_corners = []
        invalid = []

        view.line_width = 1
        loop.each { |corner|
          #puts corner.length
          #puts corner.inspect

          command, vertex, tool_position, tool_offset, tool_fillet, dog_bone_points, existing_fillet = corner
          tool_path << tool_position
          fillet_corners << tool_position unless tool_offset.nil?
          # Corner Radius
          view.line_stipple = ''
          view.drawing_color = 'orange'
          view.draw(GL_LINES, vertex.position, tool_position)
          # Catch Invalid
          if command == :invalid
            invalid << vertex.position
          end
          # Draw Corner
          unless tool_offset.nil?
            # Tool Fillet
            view.line_stipple = ''
            view.drawing_color = 'purple'
            view.draw(GL_LINE_STRIP, tool_fillet)
            #
            view.line_stipple = '-'
            view.draw_lines(tool_position, tool_fillet.first, tool_position, tool_fillet.last)
            # Tool Offset
            view.line_stipple = '.'
            view.draw_lines(tool_position, tool_offset)
            view.line_stipple = ''
            view.draw_points(tool_offset, 10, 3, 'purple')
            # Dog Bone Fillet
            view.drawing_color = 'red'
            view.draw(GL_LINE_STRIP, dog_bone_points)
            #
            if existing_fillet
              points = vertex.edges.first.curve.vertices.collect { |v| v.position }
              view.line_stipple = '-'
              view.drawing_color = 'black'
              view.draw_lines(vertex.position, points.first, vertex.position, points.last)
            end
          end
        }
        # Tool Path
        view.drawing_color = 'purple'
        view.line_stipple = '_'
        view.draw(GL_LINE_LOOP, tool_path)
        # Tool Path Corners
        view.line_stipple = ''
        view.draw_points(tool_path, 10, 4, 'purple')
        # Tool Path Fillet Corners
        view.draw_points(fillet_corners, 10, 1, 'purple') unless fillet_corners.empty?
        # Invalid Points
        view.line_width = 2
        view.draw_points(invalid, 20, 6, 'red') unless invalid.empty?
        @drawn = true
      }
    end


    def fillets(face)
      # loops = []
      # corners = []
      # corners << [vertex, tool_position, tool_offset, tool_fillet, dog_bone_points]
      # corners << [vertex, tool_position]
      # loops << corners
      loops = []
      face.loops.each { |loop|
        corners = []
        points = []
        loop.edgeuses.each { |edgeuse|
          edge1 = edgeuse.edge
          edge2 = edgeuse.next.edge

          # If we compare edges that's both part of existing fillet, then we want to
          # ignore these. When edge1 is a normal edge and edge2 is a fillet we add
          # the original point which created that corner. That point is the mid vertex in
          # the fillet curve.
          next if is_fillet?([edge1]) && is_fillet?([edge1])

          existing_fillet = false
          if is_fillet?([edge2])
            vertex = edge2.curve.vertices[ edge2.curve.vertices.length / 2 ]
            # Resolve edge2
            if edge2.curve.vertices.first.used_by?(edge1)
              other_vertex = edge2.curve.vertices.last
            else
              other_vertex = edge2.curve.vertices.first
            end
            edge2 = (other_vertex.edges - edge2.curve.edges).first
            existing_fillet = true
          else
            vertex = PLUGIN.common_vertex(edge1, edge2)
          end

          line1 = edge1.line
          line2 = edge2.line
          # Orient lines to run in the same direction
          line1[1].reverse! if edge1.reversed_in?(face)
          line2[1].reverse! if edge2.reversed_in?(face)
          point = vertex.position

          # Calculate the angle
          angle = line1[1].angle_between(line2[1])
          angle = Math::PI - angle
          half_angle = angle / 2

          # Find out if it turns right or left. Right turns are the turns where we
          # want to create out fillets.
          cross1 = line1[1] * face.normal
          cross2 = line2[1] * face.normal
          cross = cross1 * cross2
          turn_right = (cross.z > 0.0) ? false : true

          # Find the centre line going between the two edges and ensure it runs
          # towards the corner.
          vector = line1[1] * line2[1]
          unless vector.valid?
            # Colinear edges - skip this vertex as it is not a corner.
            next
          end
          tr = Geom::Transformation.rotation(point, vector, half_angle)
          mid_v = line2[1].transform(tr).normalize
          mid_v.reverse! if turn_right
          # ...
          mid_v.reverse! if face.normal.z > 0.0

          # Calculate the offset point
          radius = @tool_size / 2
          offset = PLUGIN.csc(half_angle) * radius
          op = point.offset(mid_v, offset)

          # If two edges are close to co-linear then ignore it. This is to account
          # for SketchUp's lack of true arcs/curves.
          # (?) Ignore vertices within existing arcs?
          # (!) Angle should be user configurable
          if angle < 10.degrees ||
            ( ( edge1.curve && edge2.curve ) && edge1.curve == edge2.curve )
            corners << [:offset, vertex, op]
            next
          end

          # Draw tool corner fillet
          if turn_right
            normal = line1[1] * line2[1]
            fillet_angle = Math::PI - angle
            hf_angle = fillet_angle / 2
            segments = arc_segments(fillet_angle, @segments, true)
            tool_fillet = arc(op, mid_v.reverse, normal, radius, hf_angle, -hf_angle, segments)

            p1 = op.project_to_line(line1)
            p2 = op.project_to_line(line2)

            # Movement of tool to create fillet
            distance = op.distance(point) - radius
            tool_end = op.offset(mid_v.reverse, distance)
            # Draw the cut-fillet
            if angle < 90.degrees
              segments = arc_segments(Math::PI, @segments, true)
              fillet_points = arc(tool_end, mid_v.reverse, face.normal, radius, 90.degrees, -90.degrees, segments)

              l1 = [fillet_points.first, mid_v]
              l2 = [fillet_points.last, mid_v]

              fillet_points.unshift( Geom.intersect_line_line(l1, line1) )
              fillet_points << Geom.intersect_line_line(l2, line2)
            else
              start_angle = (Math::PI * 2) - angle
              arc_angle = Math::PI + angle
              segments = arc_segments(arc_angle, @segments, true)
              fillet_points = arc(tool_end, mid_v, face.normal, radius, start_angle, angle, segments)
            end
            # (!) Hack
            if tool_fillet.length > 1
              if existing_fillet
                corners << [:cut, vertex, op, tool_end, tool_fillet, fillet_points, true]
              else
                corners << [:cut, vertex, op, tool_end, tool_fillet, fillet_points]
              end
            else
              corners << [:offset, vertex, op]
            end
          else
            corners << [:offset, vertex, op]
          end
        } # loop.edgeuses
        loops << corners
      } # face.loops
      return loops
    end


    def is_fillet?(egdes)
      return egdes.any? { |edge|
        if edge.curve.nil?
          false
        else
          not edge.curve.get_attribute(PLUGIN_ID, 'Type').nil?
        end
      }
    end


    def arc(center, xaxis, normal, radius, start_angle, end_angle, num_segments)
      # Generate the first point.
      t = Geom::Transformation.rotation(center, normal, start_angle )
      points = []
      points << center.offset(xaxis, radius).transform(t)
      # Prepare a transformation we can repeat on the last entry in point to complete the arc.
      t = Geom::Transformation.rotation(center, normal, (end_angle - start_angle) / num_segments )
      1.upto(num_segments) { |i|
        points << points.last.transform(t)
      }
      return points
    end

    def circle(center, normal, radius, num_segments)
      points = arc(center, normal.axes.x, normal, radius, 0.0, Math::PI * 2, num_segments)
      points.pop
      return points
    end

    # Calculates the number of segments in an arc given the segments of a full circle. This
    # will give a close visual quality of the arcs and circles.
    #
    # force_even is useful to ensure the segmented arc's apex hit the apex of the real arc
    def arc_segments(angle, full_circle_segments, force_even = false)
      segments = (full_circle_segments * (angle / (Math::PI * 2))).to_i
      segments += 1 if force_even && segments % 2 > 0 # if odd
      return segments
    end

  end # class Dog_Bone


  def self.common_vertex(edge1, edge2)
    edge1.vertices.each { |v|
      return v if v.used_by?(edge1) && v.used_by?(edge2)
    }
  end


  def self.start_operation(name)
    model = Sketchup.active_model
    if Sketchup.version.split('.')[0].to_i >= 7
      model.start_operation(name, true)
    else
      model.start_operation(name)
    end
  end

end # module
