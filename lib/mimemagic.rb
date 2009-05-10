require 'mimemagic_tables'
require 'stringio'

# Mime type detection
class MimeMagic
  VERSION = '0.1.1'

  attr_reader :type, :mediatype, :subtype

  # Mime type by type string
  def initialize(type)
    @type      = type
    @mediatype = @type.split('/')[0]
    @subtype   = @type.split('/')[1]
  end

  # Add custom mime type. You have to
  # specify the type, a string list of file extensions,
  # a string list of parent mime types and an optional
  # detector block for magic detection.
  def self.add(type, extensions, parents, *magics)
    TYPES[type] = [extensions, parents, block_given? ? proc(&block) : nil]
    extensions.each do |ext|
      EXTENSIONS[ext] = type
    end
    MAGIC.unshift [type, magics] if magics
  end

  # Returns true if type is a text format
  def text?
    child_of? 'text/plain'
  end

  # Returns true if type is child of parent type
  def child_of?(parent)
    child?(type, parent)
  end

  # Get string list of file extensions
  def extensions
    TYPES.key?(type) ? TYPES[type][0] : []
  end

  # Lookup mime type by file extension
  def self.by_extension(ext)
    ext = ext.downcase
    mime = EXTENSIONS[ext] || (ext[0..0] == '.' && EXTENSIONS[ext[1..-1]])
    mime ? new(mime) : nil
  end

  # Lookup mime type by magic content analysis
  # That could be slow
  def self.by_magic(content)
    io = content.respond_to?(:seek) ? content : StringIO.new(content.to_s, 'rb')
    mime = MAGIC.find {|type, matches| magic_match(io, matches) }
    mime ? new(mime[0]) : nil
  end

  # Return type as string
  def to_s
    type
  end

  # Allow comparison with string
  def ==(x)
    type == x.to_s
  end

  private

  def child?(child, parent)
    return true if child == parent
    TYPES.key?(child) ? TYPES[child][1].any? {|p| child?(p, parent) } : false
  end

  def self.magic_match(io, matches)
    matches.any? do |offset, value, children|
      if Range === offset
        io.seek(offset.begin)
        match = io.read(offset.end - offset.begin + value.length).include?(value)
      else
        io.seek(offset)
        match = value == io.read(value.length)
      end
      match && (!children || magic_match(io, children))
    end
  rescue
    false
  end
end
