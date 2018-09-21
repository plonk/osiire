#!/usr/bin/ruby
require 'chunky_png'

fail unless ARGV.length > 0
tileset = ChunkyPNG::Image.from_file(ARGV[0])
$REGISTERS = [0xff00ff]
MOD6_CHAR = ['@', 'A', 'C', 'G', 'O', '_']

def color_register(rgba)
  rgb = rgba >> 8
  reg = $REGISTERS.index(rgb)
  if reg
    return reg
  else
    #puts "%06X" % rgb
    $REGISTERS.push(rgb)
    return $REGISTERS.size - 1
  end
end

out = StringIO.new
current_register = nil

tileset.height.times do |y|
  tileset.width.times do |x|
    reg = color_register(tileset[x,y])
    if current_register != reg
      current_register = reg
      out.write "\##{reg}"
    end
    if reg == 0
      out.write "?"
    else
      char = MOD6_CHAR[y % 6]
      out.write "#{char}"
    end
  end
  if y % 6 == 5
    out.write "$-"
  else
    out.write "$"
  end
end

print "\eP" + "7;1;75q"

# aspect ratio 1/1
print "\"1;1;#{tileset.width};#{tileset.height}" 

$REGISTERS.each.with_index do |rgb, i|
  b = (rgb & 0xff) * 100 / 255
  g = (rgb >> 8 & 0xff) * 100 / 255
  r = (rgb >> 16 & 0xff) * 100 / 255
  print "\##{i};2;#{r};#{g};#{b}"
end

print out.string

print "\e\\"
