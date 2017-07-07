#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'

require 'tt_milling/debug'
require 'tt_milling/fillet'
require 'tt_milling/parts'


module TT::Plugins::MillingTools

  unless file_loaded?( __FILE__ )
    menu = UI.menu('Plugins').add_submenu(EXTENSION[:name])
    menu.add_item('Dog-Bone Fillets') { self.dog_bone }
    menu.add_separator
    menu.add_item('Generate Cut Parts') { self.generate_parts }

    file_loaded(__FILE__)
  end

end # module
