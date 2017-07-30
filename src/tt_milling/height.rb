#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

require 'set'
require 'tt_milling/utils/geom'
require 'tt_milling/utils/object_info'
require 'tt_milling/utils/walker'


module TT::Plugins::MillingTools

  def self.prompt_part_height
    8 / 0
    # Prompt the user.
    prompts = ['Part Height:']
    defaults = [2.mm]
    input = UI.inputbox(prompts, defaults, 'Adjust part height')
    return unless input
    # Extract user input.
    height = input[0]
    # Adjust the parts to the given height.
    model = Sketchup.active_model
    entities = model.selection.empty? ? model.active_entities : model.selection
    model.start_operation('Generate Cut Parts', true)
    self.adjust_parts_height(entities, height)
    model.commit_operation
  end

  def self.adjust_parts_height(entities, height)
    processed = Set.new
    self.walk_instances(entities) { |instance, transformation|
      definition = self.definition(instance)
      # Only adjust each definition affected once.
      next if processed.include?(definition)
      processed << definition
      # Offset the faces opposite of the ground.
      self.adjust_part_height(definition.entities, height)
    }
  end

  def self.adjust_part_height(entities, height)
    faces = []
    vectors = []
    entities.grep(Sketchup::Face) { |face|
      next unless face.normal.samedirection?(Z_AXIS)
      # Get the height of the part.
      face_point = face.vertices.first.position
      ground_point = face_point.project_to_plane(GROUND)
      part_height = face_point.distance(ground_point)
      # Compute the offset.
      offset = height - part_height
      vector = Geom::Vector3d.new(0, 0, offset)
      faces << face
      vectors << vector
      # face.material = 'red'
    }
    entities.transform_by_vectors(faces, vectors)
  end

end # module
