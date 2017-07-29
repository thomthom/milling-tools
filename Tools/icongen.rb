require 'fileutils'

PROGRAM_FILES = File.expand_path(ENV['PROGRAMW6432'])

SOLUTION_PATH = File.expand_path(File.join(__dir__, '..'))
EXTENSION_SOURCE_PATH = File.join(SOLUTION_PATH, 'src')
EXTENSION_SUPPORT_PATH = File.join(EXTENSION_SOURCE_PATH, 'tt_milling')
EXTENSION_IMAGE_PATH = File.join(EXTENSION_SUPPORT_PATH, 'images')


# TODO: Convert to Skippy command.
module Inkscape

  INKSCAPE_PATH = File.join(PROGRAM_FILES, 'Inkscape')
  INKSCAPE = File.join(INKSCAPE_PATH, 'inkscape.exe')

  puts "Inkscape: #{INKSCAPE} (#{File.exist?(INKSCAPE)})"

  def self.convert_svg_to_pdf(input, output)
    svg_filename = self.normalise_path(input)
    pdf_filename = self.normalise_path(output)
    arguments = %(-f "#{svg_filename}" -A "#{pdf_filename}")
    self.command(arguments)
  end

  def self.convert_svg_to_png(input, output, size)
    svg_filename = self.normalise_path(input)
    png_filename = self.normalise_path(output)
    arguments = %(-f "#{svg_filename}" -e "#{png_filename}" -w #{size} -h #{size})
    self.command(arguments)
  end

  def self.normalise_path(path)
    path.tr('/', '\\')
  end

  def self.command(arguments)
    inkscape = INKSCAPE.tr('/', '\\')
    inkscape = self.normalise_path(INKSCAPE)
    command = %("#{inkscape}" #{arguments})
    puts command
    puts `#{command}`
  end

end # module

# source_path = File.join(SOLUTION_PATH, 'Media', 'Toolbar Icons')
source_path = EXTENSION_IMAGE_PATH
target_path = EXTENSION_IMAGE_PATH

puts "Source path: #{source_path}"
puts "Target path: #{target_path}"

large_postfix = '_Large'
small_postfix = '_Small'

filter = File.join(source_path, '*.svg')
Dir.glob(filter).each { |source_file|
  puts ''
  puts source_file

  filename = File.basename(source_file)
  basename = File.basename(source_file, '.svg')

  # Then we generate the desired filenames.
  svg = "#{basename}.svg"
  pdf = "#{basename}.pdf"

  svg_filename = File.join(target_path, svg)
  pdf_filename = File.join(target_path, pdf)

  # Generate the PDF.
  puts "> #{svg} => #{pdf}"
  Inkscape.convert_svg_to_pdf(source_file, pdf_filename)

  puts "> SVG => PNG"
  png_large_filename = File.join(target_path, "#{basename}#{large_postfix}.png")
  png_small_filename = File.join(target_path, "#{basename}#{small_postfix}.png")
  puts "> #{svg} => #{png_large_filename}"
  puts "> #{svg} => #{png_small_filename}"
  Inkscape.convert_svg_to_png(source_file, png_large_filename, 32)
  Inkscape.convert_svg_to_png(source_file, png_small_filename, 24)
}
