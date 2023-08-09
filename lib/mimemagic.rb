# frozen_string_literal: true

require 'mimemagic/tables'
require 'mimemagic/version'

require 'stringio'

MimeMagic.parse_database

# Mime type detection
class MimeMagic
  attr_reader :type, :mediatype, :subtype

  # Initialize a new MIME type by string
  def initialize(type)
    @type = type.to_s.strip
    @mediatype, @subtype = type.split('/', 2)
  end

  # Syntactic sugar alias for constructor.
  #
  # @param type [#to_s] a string-like object representing a MIME type.
  #
  # @return [MimeMagic] the instantiated object.
  #
  def self.[] type
    new type
  end

  # Add a custom MIME type to the internal dictionary.
  #
  # @param type [#to_s] the type
  # @param extensions [Array<#to_s>] file extensions
  # @param parents [Array<#to_s>] parent types
  # @param magic [Array] MIME "magic" specification
  # @param aliases [Array<#to_s>] alternative names for the type
  # @param comment [#to_s] a comment
  #
  def self.add type,
      extensions: [], parents: [], magic: [], comment: nil, aliases: []
    type = type.to_s.strip.downcase
    extensions = [options[:extensions]].flatten.compact
    aliases = [options[:aliases] || []].flatten.compact
    t = TYPES[type] = [extensions, [options[:parents]].flatten.compact,
                   options[:comment], type, aliases]
    aliases.each { |a| TYPES[a] = t }
    extensions.each {|ext| EXTENSIONS[ext] = type }

    MAGIC.unshift [type, options[:magic]] if options[:magic]

    true # output is ignored
  end

  # Removes a MIME type from the dictionary. You might want to do this if
  # you're seeing impossible conflicts (for instance, application/x-gmc-link).
  #
  # @note All associated extensions and magic are removed too.
  #
  # @param type [#to_s] the type to remove.
  #
  def self.remove(type)
    EXTENSIONS.delete_if {|ext, t| t == type }
    MAGIC.delete_if {|t, m| t == type }
    TYPES.delete(type)

    true # output is also ignored
  end

  # Returns true if type is a text format.
  def text?; mediatype == 'text' || child_of?('text/plain'); end

  # Determine if the type is an image.
  def image?; mediatype == 'image'; end

  # Determine if the type is audio.
  def audio?; mediatype == 'audio'; end

  # Determine if the type is video.
  def video?; mediatype == 'video'; end

  # Returns true if type is child of parent type
  def child_of?(parent)
    self.class.child?(type, parent)
  end

  # Get string list of file extensions.
  def extensions
    TYPES.fetch(type, [[]]).first.map { |e| e.to_s.dup }
  end

  # Get MIME comment.
  def comment
    TYPES.fetch(type, [nil, nil, nil])[2].to_s.dup
  end

  # Look up MIME type by file extension
  def self.by_extension(ext)
    ext  = ext.to_s.downcase.delete_prefix ?.
    mime = EXTENSIONS[ext]
    mime && new(mime)
  end

  # Look up MIME type by filename
  def self.by_path(path)
    by_extension(File.extname(path))
  end

  # Look up MIME type by magic content analysis.
  # This is a slow operation.
  def self.by_magic(io, default: false)
    default = coerce_default io, default
    mime = magic_match(io, :find) or return default
    new mime || default
  end

  # Return all matching MIME types by magic content analysis.
  # This is a slower operation.
  def self.all_by_magic(io, default: false)
    default = coerce_default io, default
    out = magic_match(io, :select).map { |mime| new mime.first }
    out << default if out.empty? and default
    out
  end

  # Return the type as a string.
  def to_s
    type
  end

  # Compare the equality of the type with another (or plain string).
  def eql?(other)
    type == other.to_s
  end

  alias_method :==, :eql?

  def hash
    type.hash
  end

  def self.child?(child, parent)
    child == parent || TYPES.fetch(child, [nil, []])[1].any? do |p|
      child? p, parent
    end
  end

  # Return the canonical type.
  #
  # @return [MimeMagic, nil] the canonical type, if present.
  #
  def canonical
    self.class.canonical type
  end

  # Return the canonical type.
  #
  # @param type [#to_s] the type to test
  #
  # @return [MimeMagic, nil] the canonical type, if present.
  #
  def self.canonical type
    t = TYPES[type.to_s.downcase] or return
    new t[3]
  end

  # Fetches the immediate parent types.
  #
  # @return [Array<MimeMagic>] the type's parents
  #
  def parents
    out = TYPES.fetch(type.to_s.downcase, [nil, []])[1].map do |x|
      self.class.new x
    end
    # add this unless we're it
    out << self.class.new('application/octet-stream') unless
      [type.downcase, out.last].any? { |x| x == 'application/octet-stream' }
    out
  end

  # Fetches the entire inheritance hierarchy for the given MIME type.
  #
  # @return [Array<MimeMagic>] the type's lineage
  #
  def lineage
    ([self] + parents.map { |t| t.lineage }.flatten).uniq
  end

  alias_method :ancestor_types, :lineage

  # Determine if the type is an alias.
  #
  def alias?
    type != canonical.type
  end

  # Return the type's aliases.
  #
  def aliases
    self.class.aliases type
  end

  # Return the type's aliases.
  #
  def self.aliases type
    TYPES.fetch(type.to_s.downcase, [nil, nil, nil, nil, []])[4].map do |t|
      new t
    end
  end

  # Determine if an input is binary.
  #
  # @param thing [#to_s, #read]
  #
  # @return [true, false]
  #
  def self.binary? thing
    sample = nil

    # get some stuff out of the IO or get a substring
    if %i[seek tell read].all? { |m| thing.respond_to? m }
      pos = thing.tell
      thing.seek 0, 0
      sample = thing.read 100
      thing.seek pos
    elsif thing.respond_to? :to_s
      str = thing.to_s
      # if it contains a slash
      test = if str.include? ?/
               canonical(str) || by_extension(str.split(?.).last)
             else
               by_extension str.split(?.).last
             end

      return test.lineage.include? 'text/plain' if test

      sample = str[0,100]
    end

    # consider this to be 'binary' if empty
    return true if sample.empty?
    # control codes minus ordinary whitespace
    /[\x0-\x8\xe-\x1f\x7f]/.match? sample.b
  end

  private

  def self.coerce_default io, default
    case default
    when nil, false then nil
    when MimeMagic then default
    when String, -> x { x.respond_to? :to_s } then new default
    else default_type io
    end
  end

  def self.magic_match(io, method)
    return magic_match(StringIO.new(io.to_s), method) unless io.respond_to?(:read)

    io.binmode if io.respond_to?(:binmode)
    io.set_encoding(Encoding::BINARY) if io.respond_to?(:set_encoding)
    buffer = "".encode(Encoding::BINARY)

    MAGIC.send(method) { |type, matches| magic_match_io(io, matches, buffer) }
  end

  def self.magic_match_io(io, matches, buffer)
    matches.any? do |offset, value, children|
      match =
        if Range === offset
          io.read(offset.begin, buffer)
          x = io.read(offset.end - offset.begin + value.bytesize, buffer)
          x && x.include?(value)
        else
          io.read(offset, buffer)
          io.read(value.bytesize, buffer) == value
        end
      io.rewind
      match && (!children || magic_match_io(io, children, buffer))
    end
  end

end
