#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

require 'tt_milling/debug'
require 'tt_milling/fillet'


module TT::Plugins::MillingTools

  unless file_loaded?( __FILE__ )
    menu = UI.menu('Plugins').add_submenu(EXTENSION[:name])
    menu.add_item('Dog-Bone Fillet') { self.dog_bone }

    file_loaded(__FILE__)
  end

end # module
