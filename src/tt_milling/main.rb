#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'

require 'tt_milling/command'
require 'tt_milling/debug'
require 'tt_milling/fillet'
require 'tt_milling/ground'
require 'tt_milling/height'
require 'tt_milling/parts'


module TT::Plugins::MillingTools

  unless file_loaded?( __FILE__ )
    # TODO: Add PDF and PNG versions of the icons.
    cmd = Command.new('Dog-Bone Fillets') {
      self.dog_bone
    }
    cmd.status_bar_text = 'Tool to generate dog-bone fillets.'
    cmd.icon = File.join(PATH, 'images', '045-drill')
    dog_bone_tool = cmd

    cmd = Command.new('Generate Cut Parts') {
      self.generate_parts
    }
    cmd.status_bar_text = 'Generates 2D cut shapes for each part.'
    cmd.icon = File.join(PATH, 'images', '006-saw-1')
    generate_parts = cmd

    cmd = Command.new('Adjust Part Height') {
      self.prompt_part_height
    }
    cmd.status_bar_text = 'Adjust the height of the selected parts.'
    cmd.icon = File.join(PATH, 'images', 'caliper')
    adjust_height = cmd

    cmd = Command.new('Set Ground Plane') {
      self.ground_plane_tool
    }
    cmd.status_bar_text = 'Pick a face to set the ground place for instances.'
    cmd.icon = File.join(PATH, 'images', 'cube-1')
    ground_plane_tool = cmd


    menu = UI.menu('Plugins').add_submenu(EXTENSION[:name])
    menu.add_item(dog_bone_tool)
    menu.add_separator
    menu.add_item(generate_parts)
    menu.add_item(adjust_height)
    menu.add_separator
    menu.add_item(ground_plane_tool)
    # TODO: Credit icon pack: http://www.flaticon.com/packs/industry-10

    toolbar = UI::Toolbar.new(EXTENSION[:name])
    toolbar.add_item(dog_bone_tool)
    toolbar.add_separator
    toolbar.add_item(generate_parts)
    toolbar.add_item(adjust_height)
    toolbar.add_separator
    toolbar.add_item(ground_plane_tool)
    toolbar.restore

    file_loaded(__FILE__)
  end

end # module
