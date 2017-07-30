#-------------------------------------------------------------------------------
#
#    Author: Thomas Thomassen
# Copyright: Copyright (c) 2010–2017
#   License: None
#
#-------------------------------------------------------------------------------


module TT::Plugins::MillingTools

  ### CONSTANTS ### ------------------------------------------------------------

  EXTENSION_ID = EXTENSION.product_id

  unless defined?(DEBUG)
    # Sketchup.write_default("TT_MillingTools", "DebugMode", true)
    DEBUG = Sketchup.read_default(EXTENSION_ID, "DebugMode", false)
  end

  # Minimum version of SketchUp required to run the extension.
  MINIMUM_SKETCHUP_VERSION = 14

  # TODO: Configure depending on build.
  # Default base URI. Use Settings.read('Server', SERVER_URL) to get the
  # actual server to use.
  # TT::Plugins::MillingTools.settings[:server] = 'http://www.evilsoftwareempire.local'
  SERVER_URL = 'http://evilsoftwareempire.com'.freeze

  # URI to the extension product page.
  EXTENSION_URL = "http://extensions.sketchup.com/content/milling-tools".freeze


  ### COMPATIBILITY CHECK ### --------------------------------------------------

  # Using SU2014 to test 32bit builds - so using a preference setting to be set
  # to override the version check.
  if Sketchup.version.to_i < MINIMUM_SKETCHUP_VERSION

    # Not localized because we don't want the Translator and related
    # dependencies to be forced to be compatible with older SketchUp versions.
    version_name = "20#{MINIMUM_SKETCHUP_VERSION}"
    message = "#{EXTENSION.name} require SketchUp #{version_name} or newer."
    messagebox_open = false # Needed to avoid opening multiple message boxes.
    # Defer with a timer in order to let SketchUp fully load before displaying
    # modal dialog boxes.
    UI.start_timer(0, false) {
      unless messagebox_open
        messagebox_open = true
        UI.messagebox(message)
        # Must defer the disabling of the extension as well otherwise the
        # setting won't be saved. I assume SketchUp save this setting after it
        # loads the extension.
        if @extension.respond_to?(:uncheck)
          @extension.uncheck
        end
      end
    }

  else # Sketchup.version

    ### ERROR HANDLER ### ------------------------------------------------------

    Sketchup.require "tt_milling/vendor/error-reporter/error_reporter"

    # Sketchup.write_default("TT_MillingTools", "ErrorServer", "sketchup.thomthom.local")
    # Sketchup.write_default("TT_MillingTools", "ErrorServer", "sketchup.thomthom.net")
    server = Sketchup.read_default(EXTENSION_ID, "ErrorServer",
      "sketchup.thomthom.net")

    extension = Sketchup.extensions[EXTENSION.name]

    config = {
      :extension_id => EXTENSION_ID,
      :extension    => extension,
      :server       => "http://#{server}/api/v1/extension/report_error",
      :support_url  => "#{EXTENSION_URL}",
      :debug        => DEBUG
    }
    ERROR_REPORTER = ErrorReporter.new(config)


    ### Initialization ### -----------------------------------------------------

    begin
      Sketchup::require 'tt_milling/main'
    rescue Exception => exception
      ERROR_REPORTER.handle(exception)
    end

  end # if Sketchup.version

end # module

