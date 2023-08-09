# frozen_string_literal: true

require 'mimemagic/tables'
require 'mimemagic/version'

require 'stringio'

MimeMagic.parse_database

# Mime type detection
class MimeMagic
  attr_reader :type, :mediatype, :subtype, :params

  # Initialize a new MIME type by string
  def initialize(type)
    # chop off params
    @type, *params = type.to_s.strip.split(/(?:\s*;\s*)+/)
    @params = params.map { |x| x.split(/\s*=\s*/, 2) } unless params.empty?
    @mediatype, @subtype = @type.split ?/, 2
  end

  # Syntactic sugar alias for constructor.
  #
  # @param type [#to_s] a string-like object representing a MIME type
  #  or file extension.
  #
  # @return [MimeMagic] the instantiated object.
  #
  def self.[] type
    type = type.to_s.downcase.strip
    return by_extension type unless type.to_s.include? ?/
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
    extensions = [extensions].flatten.compact
    aliases = [[aliases] || []].flatten.compact
    t = TYPES[type] = [extensions, [parents].flatten.compact,
                   comment, type, aliases]
    aliases.each { |a| TYPES[a] = t }
    extensions.each {|ext| EXTENSIONS[ext] = type }

    MAGIC.unshift [type, magic] if magic

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
  #
  # @param parent [#to_s] a candidate parent type
  #
  # @return [true, false] whether `self` is a child of `parent`
  #
  def child_of?(parent)
    self.class.child?(type, parent)
  end

  # Get string list of file extensions.
  #
  # @return [Array<String>] associated file extensions.
  #
  def extensions
    TYPES.fetch(type, [[]]).first.map { |e| e.to_s.dup }
  end

  # Get MIME comment.
  def comment
    TYPES.fetch(type, [nil, nil, nil])[2].to_s.dup
  end

  # Look up MIME type by file extension. When `default` is true
  #
  # @param path [#to_s]
  # @param default [false, true, #to_s, MimeMagic] a default fallback type
  def self.by_extension ext, default: false
    ext = ext.to_s.downcase.delete_prefix ?.
    default = coerce_default '', default
    mime = EXTENSIONS[ext]
    mime ? new(mime) : default
  end

  # Look up MIME type by filename.
  #
  # @param path [#to_s]
  # @param default [false, true, #to_s, MimeMagic] a default fallback type
  #
  def self.by_path path, default: false
    by_extension(File.extname(path), default: default)
  end

  # Look up MIME type by magic content analysis.
  #
  # @note This is a relatively slow operation.
  #
  # @param io [#read, #to_s] the IO/String-like object to check for magic
  # @param default [false, true, #to_s, MimeMagic] a default fallback type
  #
  # @return [nil, MimeMagic] a matching type
  #
  def self.by_magic io, default: false
    default = coerce_default io, default
    mime = magic_match(io, :find) or return default
    new mime.first
  end

  # Return all matching MIME types by magic content analysis.
  # @note This is a relatively slow operation.
  #
  # @param io [#read, #to_s] the IO/String-like object to check for magic
  # @param default [false, true, #to_s, MimeMagic] a default fallback type
  #
  # @return [Array<MimeMagic>] all matching types
  #
  def self.all_by_magic io, default: false
    default = coerce_default io, default
    out = magic_match(io, :select).map { |mime| new mime.first }
    out << default if out.empty? and default
    out
  end

  # Return a diagnostic representation of the object.
  #
  # @return [String] a string representing the object.
  #
  def inspect
    out = @type
    out = [out, @params.map { |x| x.join ?= }].join ?; if
      @params and !@params.empty?
    %q[<%s "%s">] % [self.class, out]
  end

  # Return the type as a string.
  #
  # @return [String] the type, as a string.
  #
  def to_s
    type
  end

  # Compare the equality of the type with another (or plain string).
  #
  # @param other [#to_s] the other to teset
  #
  # @return [false, true] whether the two are equal.
  #
  def eql?(other)
    type == other.to_s
  end

  alias_method :==, :eql?

  # Return the object's (the underlying type string) hash.
  #
  # @return [Integer] the hash value.
  #
  def hash
    type.hash
  end

  # Returns true if type is child of parent type.
  #
  # @param child [#to_s] a candidate child type
  # @param parent [#to_s] a candidate parent type
  #
  # @return [true, false] whether `self` is a child of `parent`
  #
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

  # Determine if the type is an alias.
  #
  # @return [false, true] whether the type is an alias.
  #
  def alias?
    type != canonical.type
  end

  # Return the type's aliases.
  #
  # @return [Array<MimeMagic>] the aliases, if any.
  #
  def aliases
    self.class.aliases type
  end

  # Return the type's aliases.
  #
  # @param type [#to_s] the type to check
  #
  # @return [Array<MimeMagic>] the aliases, if any.
  #
  def self.aliases type
    TYPES.fetch(type.to_s.downcase, [nil, nil, nil, nil, []])[4].map do |t|
      new t
    end
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
    out << self.class.new('application/octet-stream') if
      out.empty? and type.downcase != 'application/octet-stream'

    out.uniq
  end

  # Fetches the entire inheritance hierarchy for the given MIME type.
  #
  # @return [Array<MimeMagic>] the type's lineage
  #
  def lineage
    ([self] + parents.map { |t| t.lineage }.flatten).uniq
  end

  alias_method :ancestor_types, :lineage

  # Determine if the type is binary.
  #
  # @return [true, false, nil] whether the input is binary (`nil` if
  #  indeterminate).
  #
  def binary?
    not lineage.include? 'text/plain'
  end

  # Determine if an input is binary.
  #
  # @param thing [#read, #to_s] the IO-like or String-like thing to
  #  test; can also be a file name/path/extension or MIME type.
  #
  # @return [true, false, nil] whether the input is binary (`nil` if
  #  indeterminate).
  #
  def self.binary? thing
    sample = ''

    # get some stuff out of the IO or get a substring
    if thing.is_a? MimeMagic
      return thing.binary?
    elsif %i[seek tell read].all? { |m| thing.respond_to? m }
      pos = thing.tell
      thing.seek 0, 0
      sample = thing.read 256
      thing.seek pos
    elsif thing.respond_to? :to_s
      str = thing.to_s
      # if it contains a slash it could be either a path or mimetype
      test = if str.include? ?/
               canonical(str) || by_extension(str.split(?.).last)
             else
               by_extension str.split(?.).last
             end

      return test.binary? if test

      sample = str[0, 256]
    else
      # nil if we don't know what this thing is
      return
    end

    # consider this to be 'binary' if empty
    return true if sample.empty?
    # control codes minus ordinary whitespace
    /[\x0-\x8\xe-\x1f\x7f]/.match? sample.b
  end

  # Return either `application/octet-stream` or `text/plain` depending
  # on whether the thing is binary.
  #
  # @param thing [#read, #to_s] the thing (IO-like, String-like, MIME type,
  #
  # @return [MimeMagic] the default type
  #
  def self.default_type thing
    new(binary?(thing) ? 'application/octet-stream' : 'text/plain')
  end

  private

  def self.coerce_default thing, default
    case default
    when nil, false then nil
    when true then default_type thing
    when MimeMagic then default
    when String, -> x { x.respond_to? :to_s } then new default
    else default_type thing
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
