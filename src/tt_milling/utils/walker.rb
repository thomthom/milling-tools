#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

require 'tt_milling/utils/instance'


module TT::Plugins::MillingTools

  def self.walk_instances(entities, transformation = IDENTITY.clone, &block)
    entities.each { |entity|
      next unless self.is_instance?(entity)
      tr = entity.transformation * transformation
      block.call(entity, tr)
      definition = self.definition(entity)
      self.walk_instances(definition.entities, tr, &block)
    }
  end

end # module
