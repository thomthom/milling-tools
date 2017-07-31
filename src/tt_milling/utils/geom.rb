#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools

  GROUND = [ORIGIN, Z_AXIS]


  def self.on_ground?(face)
    face.normal.parallel?(Z_AXIS) && face.vertices.all? { |vertex|
      vertex.position.on_plane?(GROUND)
    }
  end

  # @param [Sketchup::Face] face
  #
  # @return [Geom::Point3d]
  def self.face_centroid(face)
    positions = face.vertices.map { |vertex| vertex.position }
    self.average(positions)
  end

  # @param [Array<Geom::Point3d>] points
  #
  # @return [Geom::Point3d]
  def self.average(points)
    return ORIGIN.clone if points.empty?
    x = 0.0
    y = 0.0
    z = 0.0
    points.each { |point|
      x += point.x
      y += point.y
      z += point.z
    }
    n = points.size
    Geom::Point3d.new(x / n, y / n, z / n)
  end

end # module
