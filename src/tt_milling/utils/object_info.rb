#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools
  module ObjectInfo

    private

    def object_info(extra_info = "")
      %{#<#{self.class.name}:#{object_id_hex}#{extra_info}>}
    end

    def object_id_hex
      "0x%x" % (self.object_id << 1)
    end

  end # class ObjectInfo
end # module
