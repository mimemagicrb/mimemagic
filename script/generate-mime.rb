#!/usr/bin/ruby

require 'rexml/document'

def str2int(s)
  return s.to_i(16) if s[0..1].downcase == '0x'
  return s.to_i(8) if s[0..0].downcase == '0'
  s.to_i(10)
end

def get_matches(parent)
  parent.get_elements('match').map {|match|
    if match.attributes['mask']
      nil
    else
      type = match.attributes['type']
      value = match.attributes['value']
      offset = match.attributes['offset'].split(':').map {|x| x.to_i }
      offset = offset.size == 2 ? offset[0]..offset[1] : offset[0]
      case type
      when 'string'
        value.gsub!(/\\(x[\dA-Fa-f]{1,2}|0\d{1,3}|\d{1,3}|.)/) { eval("\"\\#{$1}\"") }
      when 'big16'
        value = str2int(value)
        value = ((value >> 8).chr + (value & 0xFF).chr)
      when 'big32'
        value = str2int(value)
        value = (((value >> 24) & 0xFF).chr + ((value >> 16) & 0xFF).chr + ((value >> 8) & 0xFF).chr + (value & 0xFF).chr)
      when 'little16'
        value = str2int(value)
        value = ((value & 0xFF).chr + (value >> 8).chr)
      when 'little32'
        value = str2int(value)
        value = ((value & 0xFF).chr + ((value >> 8) & 0xFF).chr + ((value >> 16) & 0xFF).chr + ((value >> 24) & 0xFF).chr)
      when 'host16' # use little endian
        value = str2int(value)
        value = ((value & 0xFF).chr + (value >> 8).chr)
      when 'host32' # use little endian
        value = str2int(value)
        value = ((value & 0xFF).chr + ((value >> 8) & 0xFF).chr + ((value >> 16) & 0xFF).chr + ((value >> 24) & 0xFF).chr)
      when 'byte'
        value = str2int(value)
        value = value.chr
      end
      children = get_matches(match)
      children.empty? ? [offset, value] : [offset, value, children]
    end
  }.compact
end

FILE = ARGV[0] || '/usr/share/mime/packages/freedesktop.org.xml'
file = File.new(FILE)
doc = REXML::Document.new(file)
extensions = {}
types = {}
magics = []
doc.each_element('mime-info/mime-type') do |mime|
  type = mime.attributes['type']
  subclass = mime.get_elements('sub-class-of').map{|x| x.attributes['type']}
  exts = mime.get_elements('glob').map{|x| x.attributes['pattern'] =~ /^\*\.([^\[\]]+)$/ ? $1.downcase : nil }.compact
  mime.get_elements('magic').each do |magic|
    priority = magic.attributes['priority'].to_i
    matches = get_matches(magic)
    magics << [priority, type, matches]
  end
  if !exts.empty?
    exts.each{|x|
      extensions[x] = type if !extensions.include?(x)
    }
    types[type] = [exts,subclass]
  end
end

magics = magics.sort {|a,b| b[0] <=> a[0] }.map {|x| [x[1], x[2]] }

puts "# Generated from #{FILE}"
puts "class MimeMagic"
puts "  private"
puts "  EXTENSIONS = {"
extensions.keys.sort.each do |key|
  puts "    '#{key}' => '#{extensions[key]}',"
end
puts "  }"
puts "  TYPES = {"
types.keys.sort.each do |key|
  exts = types[key][0].sort.inspect
  parents = types[key][1].sort.inspect
  puts "    '#{key}' => [#{exts}, #{parents}],"
end
puts "  }"
puts "  MAGIC = ["
magics.each do |type, matches|
  puts "    ['#{type}', #{matches.inspect}],"
end
puts "  ]"
puts "end"

