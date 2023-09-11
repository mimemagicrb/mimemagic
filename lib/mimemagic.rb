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

  # Syntactic sugar alias for constructor. No-op if `type` is already
  # a {MimeMagic} object.
  #
  # @param type [#to_s] a string-like object representing a MIME type
  #  or file extension.
  #
  # @return [MimeMagic] the instantiated object.
  #
  def self.[] type
    # try noop first
    return type if type.is_a? self

    # now we handle the string
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
    extensions.each {|ext| EXTENSIONS[ext] ||= type }

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
  def text?; mediatype == 'text' || descendant_of?('text/plain'); end

  # Determine if the type is an image.
  def image?; mediatype == 'image'; end

  # Determine if the type is audio.
  def audio?; mediatype == 'audio'; end

  # Determine if the type is video.
  def video?; mediatype == 'video'; end

  # Get string list of file extensions.
  #
  # @return [Array<String>] associated file extensions.
  #
  def extensions
    TYPES.fetch(type, [[]]).first.map { |e| e.to_s.dup }
  end

  # Get MIME comment.
  #
  # @return [nil, String] the comment
  #
  def comment
    TYPES.fetch(type, [nil, nil, nil])[2].to_s.dup
  end

  # Return the canonical type. Returns `nil` if the type is unknown to
  # the registry.
  #
  # @return [MimeMagic, nil] the canonical type, if present.
  #
  def canonical
    t = TYPES[type.downcase] or return
    return self if type == t[3]
    self.class.new t[3]
  end

  # Return the type's aliases.
  #
  # @return [Array<MimeMagic>] the aliases, if any.
  #
  def aliases
    TYPES.fetch(type.downcase, [nil, nil, nil, nil, []])[4].map do |t|
      self.class.new t
    end
  end

  # Determine if the type is an alias.
  #
  # @return [false, true] whether the type is an alias.
  #
  def alias?
    type != canonical.type
  end

  # Returns true if the ancestor type is anywhere in the subject
  # type's lineage. Always returns `false` if either `self` or
  # `ancestor` are unknown to the type registry.
  #
  # @param ancestor [MimeType,#to_s] the candidate ancestor type
  #
  # @return [true, false] whether `self` is a descendant of `ancestor`
  #
  def descendant_of? ancestor
    # always false if we don't know what this is
    return unless c = canonical

    # ancestor canonical could be nil which will be false
    c.lineage.include? self.class[ancestor].canonical
  end

  # Returns true if type is child of parent type. Behaves the same as
  # #descendant_of? if `recurse` is true, which is the default.
  #
  # @param parent [#to_s] a candidate parent type
  # @param recurse [true, false] whether to recurse
  #
  # @return [true, false] whether `self` is a child of `parent`
  #
  def child_of?(parent, recurse: true)
    return descendant_of? parent if recurse
    return unless c = canonical
    c.parents.include? self.class[parent].canonical
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
    ([canonical || self] + parents.map { |t| t.lineage }.flatten).uniq
  end

  alias_method :ancestor_types, :lineage

  # Determine if the _type_ is a descendant of `text/plain`. Not to be
  # confused with the class method {.binary?}, which concerns
  # arbitrary input.
  #
  # @return [true, false, nil] whether the type is binary.
  #
  def binary?
    not lineage.include? 'text/plain'
  end

  # Compare the equality of the type with another (or plain string).
  #
  # @param other [#to_s] the other to test
  #
  # @return [false, true] whether the two are equal.
  #
  def eql?(other)
    # coerce the rhs
    other = self.class[other]

    # check for an exact match
    ok = type.downcase == other.type.downcase
    return ok if ok

    # now canonicalize both sides and check
    lhs = canonical
    rhs = other.canonical

    lhs && rhs && lhs.type == rhs.type
  end

  alias_method :==, :eql?

  # Return the object's (the underlying type string) hash.
  #
  # @return [Integer] the hash value.
  #
  def hash
    type.hash
  end

  # Return the type as a string.
  #
  # @return [String] the type, as a string.
  #
  def to_s
    type
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

  # Look up MIME type by file extension. When `default` is true or a
  # value, this method will always return a value.
  #
  # @param path [#to_s]
  # @param default [false, true, #to_s, MimeMagic] a default fallback type
  #
  # @return [nil, MimeMagic] the type, if found.
  #
  def self.by_extension ext, default: false
    ext = ext.to_s.downcase.delete_prefix ?.
    default = coerce_default '', default
    mime = EXTENSIONS[ext]
    mime ? new(mime) : default
  end

  # Look up MIME type by file path. When `default` is true or a value,
  # this method will always return a value.
  #
  # @param path [#to_s] the file/path to check
  # @param default [false, true, #to_s, MimeMagic] a default fallback type
  #
  # @return [nil, MimeMagic] the type, if found.
  #
  def self.by_path path, default: false
    by_extension(File.extname(path), default: default)
  end

  # Look up MIME type by magic content analysis. When `default` is true or a
  # value, this method will always return a value.
  #
  # @note This is a relatively slow operation.
  #
  # @param io [#read, #to_s] the IO/String-like object to check for magic
  # @param default [false, true, #to_s, MimeMagic] a default fallback type
  #
  # @return [nil, MimeMagic] a matching type, if found.
  #
  def self.by_magic io, default: false
    default = coerce_default io, default
    mime = magic_match(io, :find) or return default
    new mime.first
  end

  # Return all matching MIME types by magic content analysis. When
  # `default` is true or a value, the result will never be empty.
  #
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

  # Returns true if type is child of parent type.
  #
  # @param child [#to_s] a candidate child type
  # @param parent [#to_s] a candidate parent type
  #
  # @return [true, false] whether `self` is a child of `parent`
  #
  def self.child?(child, parent, recurse: true)
    self[child].child_of? parent, recurse: recurse
  end

  # Return the canonical type.
  #
  # @param type [#to_s] the type to test
  #
  # @return [MimeMagic, nil] the canonical type, if present.
  #
  def self.canonical type
    self[type].canonical
  end

  # Return the type's aliases.
  #
  # @param type [#to_s] the type to check
  #
  # @return [Array<MimeMagic>] the aliases, if any.
  #
  def self.aliases type
    self[type].aliases
  end

  # Determine if an _input_ is binary. Not to be confused with the
  # instance method {#binary?}, which concerns the _type_.
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
    /[\x0-\x8\xe-\x1f\x7f]/n.match? sample.b
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
