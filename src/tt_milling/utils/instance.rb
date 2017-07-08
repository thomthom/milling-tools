#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools

  def self.is_instance?(entity)
    entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
  end

  def self.definition(instance)
    if instance.respond_to?(:definition)
      instance.definition
    else
      # TODO:
      raise NotImplementedError
    end
  end

end # module
