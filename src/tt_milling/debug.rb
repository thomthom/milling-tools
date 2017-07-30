#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: The MIT License
#
#-------------------------------------------------------------------------------

module TT::Plugins::MillingTools

  # TT::Plugins::MillingTools.reload
  def self.reload
    original_verbose = $VERBOSE
    $VERBOSE = nil
    load __FILE__
    x = Dir.glob(File.join(PATH, '*.rb')).each { |file|
      load file
    }
    x.size + 1
  ensure
    $VERBOSE = original_verbose
  end

end # module
