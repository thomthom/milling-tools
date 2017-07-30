#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools

  module TransformationHelper

    def scales
      a, b, c, d, e, f, g, h, i, j, k, l = to_a
      x_scale = Geom::Vector3d.new(a, b, c).length.to_f
      y_scale = Geom::Vector3d.new(e, f, g).length.to_f
      z_scale = Geom::Vector3d.new(i, j, k).length.to_f
      x_scale = -x_scale if flipped_x?
      y_scale = -y_scale if flipped_y?
      z_scale = -z_scale if flipped_z?
      [x_scale, y_scale, z_scale]
    end

    def flipped_x?
      dot_x, dot_y, dot_z = axes_dot_products()
      dot_x < 0 && flipped?(dot_x, dot_y, dot_z)
    end

    def flipped_y?
      dot_x, dot_y, dot_z = axes_dot_products()
      dot_y < 0 && flipped?(dot_x, dot_y, dot_z)
    end

    def flipped_z?
      dot_x, dot_y, dot_z = axes_dot_products()
      dot_z < 0 && flipped?(dot_x, dot_y, dot_z)
    end

    private

    def axes_dot_products
      [
        xaxis.dot(X_AXIS),
        yaxis.dot(Y_AXIS),
        zaxis.dot(Z_AXIS)
      ]
    end

    def flipped?(dot_x, dot_y, dot_z)
      dot_x * dot_y * dot_z < 0
    end

  end # module

end # module
