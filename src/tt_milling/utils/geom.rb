#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools

  GROUND = [ORIGIN, Z_AXIS]


  def self.on_ground?(face)
    face.normal.parallel?(Z_AXIS) && face.vertices.all? { |vertex|
      vertex.position.on_plane?(GROUND)
    }
  end

end # module
