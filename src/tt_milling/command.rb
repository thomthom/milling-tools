#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'tt_milling/system'


module TT::Plugins::MillingTools
# Doesn't seem possible to subclass UI::Command as the subclass's #new will
# return a UI::Command object. So instead this module is used that will extend
# the instance created with it's #create method.
#
# @example
#   cmd = Command.create('Hello World') {
#     Extension.hello_world
#   }
#   cmd.icon = 'path_to_icon/icon_base_name'
#   cmd.tooltip = 'Hello Tooltip'
#   cmd.status_bar_text = 'Everything else a UI::Command does.'
module Command

  # SketchUp allocate the object by implementing `new` - probably part of
  # older legacy implementation when that was the norm. Because of that the
  # class cannot be sub-classed directly. This module simulates the interface
  # for how UI::Command is created. `new` will create an instance of
  # UI::Command but mix itself into the instance - effectively subclassing it.
  # (yuck!)
  def self.new(title, &block)
    command = UI::Command.new(title) {
      # TODO: Add error reporter.
      # begin
        block.call
      # rescue Exception => exception
      #   ERROR_REPORTER.handle(exception)
      # end
    }
    # Default tooltip will be the title.
    command.tooltip = title
    command.extend(self)
    command
  end

  # @param [String] basename
  def icon=(basename)
    if Sketchup.version.to_i > 15
      extension = PLATFORM_OSX ? 'pdf' : 'svg'
      small_icon_file = "#{basename}.#{extension}"
      large_icon_file = "#{basename}.#{extension}"
    else
      small_icon_file = "#{basename}_Small.png"
      large_icon_file = "#{basename}_Large.png"
    end
    self.small_icon = small_icon_file
    self.large_icon = large_icon_file
  end

end # module Command
end # module
