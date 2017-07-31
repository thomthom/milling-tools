#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools

  def self.ground_plane_tool
    Sketchup.active_model.select_tool(GroundTool.new)
  end


  class GroundTool

    def initialize
      @polygon = []
      @centroid = nil
      @normal = nil
      @path = []
      @tr = nil
    end

    def deactivate(view)
      view.invalidate
    rescue Exception => exception
      ERROR_REPORTER.handle(exception)
    end

    def resume(view)
      view.invalidate
    rescue Exception => exception
      ERROR_REPORTER.handle(exception)
    end

    def suspend(view)
      view.invalidate
    rescue Exception => exception
      ERROR_REPORTER.handle(exception)
    end

    def onMouseMove(flags, x, y, view)
      pick_ground(flags, x, y, view)
      view.invalidate
    rescue Exception => exception
      ERROR_REPORTER.handle(exception)
    end

     def onLButtonUp(flags, x, y, view)
      pick_ground(flags, x, y, view)
      unless @polygon.empty?
        # puts 'Picked!'
        face = @path.last
        definition = face.parent
        # p [face, definition]
        if definition.is_a?(Sketchup::ComponentDefinition)
          centroid = SELF.face_centroid(face)
          tr_center = Geom::Transformation.new(centroid).inverse
          tr = Geom::Transformation.new(ORIGIN, face.normal.reverse) * tr_center
          inverse_tr = tr.inverse
          # p tr.to_a.each_slice(4) { |slice| p slice }
          face.model.start_operation('Set Ground Plane', true)
          definition.entities.transform_entities(tr, definition.entities.to_a)
          definition.instances.each { |instance|
            # For some reason, this doesn't work. Wrong order of operation?
            # instance.transform!(inverse_tr)
            # This correctly readjust the instance.
            itr = instance.transformation * inverse_tr
            instance.transformation = itr
          }
          face.model.commit_operation
        end
      end
      view.invalidate
    rescue Exception => exception
      ERROR_REPORTER.handle(exception)
    end

    def draw(view)
      return if @polygon.empty?

      # Fill
      view.drawing_color = [64, 64, 255, 64]
      view.draw(GL_POLYGON, @polygon)

      # Border
      view.line_stipple = ''
      view.line_width = 3
      view.drawing_color = [0, 0, 255]
      view.draw(GL_LINE_LOOP, @polygon)

      # Centroid
      style = 3 # Cross
      view.draw_points([@centroid], 10, style, [0, 0, 255])

      # Normal
      size = view.pixels_to_model(50, @centroid)
      point = @centroid.offset(@normal, size)
      view.draw(GL_LINES, @centroid, point)

      # Current Normal
      if @path.size > 1
        instance = @path[-2, 1].first
        z_axis = instance.transformation.zaxis
        point = @centroid.offset(z_axis, size)
        view.line_stipple = '_'
        view.drawing_color = [128, 0, 255]
        view.draw(GL_LINES, @centroid, point)
      end
    rescue Exception => exception
      ERROR_REPORTER.handle(exception)
    end

    private

    def pick_ground(flags, x, y, view)
      @polygon.clear
      ph = view.pick_helper(x, y)
      face = ph.picked_face
      ph.count.times { |i|
        path = ph.path_at(i)
        next unless path.last == face
        @path = path
        # Leaf transformation
        @tr = ph.transformation_at(i)
        # Normal
        @normal = face.normal.transform(@tr)
        # Polygon
        @polygon = face.outer_loop.vertices.map { |vertex|
          vertex.position.transform(@tr)
        }
        # Centroid
        @centroid = centroid(@polygon)
        break
      }
    end

    def centroid(points)
      x, y, z = ORIGIN.to_a
      points.each { |point|
        x += point.x
        y += point.y
        z += point.z
      }
      x /= points.size
      y /= points.size
      z /= points.size
      Geom::Point3d.new(x, y, z)
    end

  end # class

end # module
