require 'minitest/autorun'
require 'mimemagic'
require 'stringio'
require 'forwardable'

class TestMimeMagic < Minitest::Test
  # Do deep copy for constants of initial state.
  INIT_EXTENSIONS = Marshal.load(Marshal.dump(MimeMagic::EXTENSIONS))
  INIT_TYPES = Marshal.load(Marshal.dump(MimeMagic::TYPES))
  INIT_MAGIC = Marshal.load(Marshal.dump(MimeMagic::MAGIC))

  def setup
    extentions = Marshal.load(Marshal.dump(INIT_EXTENSIONS))
    types = Marshal.load(Marshal.dump(INIT_TYPES))
    magic = Marshal.load(Marshal.dump(INIT_MAGIC))
    MimeMagic.send(:remove_const, :EXTENSIONS) if MimeMagic.const_defined?(:EXTENSIONS)
    MimeMagic.send(:remove_const, :TYPES) if MimeMagic.const_defined?(:TYPES)
    MimeMagic.send(:remove_const, :MAGIC) if MimeMagic.const_defined?(:MAGIC)
    MimeMagic.const_set('EXTENSIONS', extentions)
    MimeMagic.const_set('TYPES', types)
    MimeMagic.const_set('MAGIC', magic)
  end

  def test_have_type_mediatype_and_subtype
    assert_equal 'text/html', MimeMagic.new('text/html').type
    assert_equal 'text', MimeMagic.new('text/html').mediatype
    assert_equal 'html', MimeMagic.new('text/html').subtype

    # a little more robust equality test perchance
    assert MimeMagic['TEXT/HTML'] == 'TeXT/HtML;charset=utf-8'

    # this was crashing because the RHS has no canonical
    assert MimeMagic['text/html'] != 'application/x-bogus'
  end

  def test_have_mediatype_helpers
    assert MimeMagic.new('text/plain').text?
    assert MimeMagic.new('text/html').text?
    assert MimeMagic.new('application/xhtml+xml').text?
    refute MimeMagic.new('application/octet-stream').text?
    refute MimeMagic.new('image/png').text?
    assert MimeMagic.new('image/png').image?
    assert MimeMagic.new('video/ogg').video?
    assert MimeMagic.new('audio/mpeg').audio?
  end

  def test_have_hierarchy
    assert MimeMagic.new('text/html').child_of?('text/plain')
    # drake-no: text/plain is an ancestor but not an immediate parent
    refute MimeMagic.new('text/x-java').child_of?('text/plain', recurse: false)
    # drake-yes
    assert MimeMagic.new('text/x-java').descendant_of?('text/plain')
  end

  def test_have_extensions
    assert_equal %w(htm html), MimeMagic.new('text/html').extensions.sort
  end

  def test_have_comment
    assert_equal 'HTML document', MimeMagic.new('text/html').comment
  end

  def test_recognize_extensions
    assert MimeMagic.by_extension('html')

    # these resolve to application/xhtml+xml instead of text/html
    # because of ambiguities in file extension associations; the data
    # file associates the former since it's first.
    #
    # assert_equal 'text/html', MimeMagic.by_extension('.html').to_s
    # assert_equal 'text/html', MimeMagic.by_extension('html').to_s
    # assert_equal 'text/html', MimeMagic.by_extension(:html).to_s

    assert_equal 'application/x-ruby', MimeMagic.by_extension('rb').to_s
    assert_nil MimeMagic.by_extension('crazy')
    assert_nil MimeMagic.by_extension('')
    # try with duplicate
    assert_equal 'application/octet-stream',
      MimeMagic.by_extension('crazy', default: true).to_s
  end

  def test_recognize_by_a_path

    # once again, ambiguities.
    #
    # assert_equal 'text/html', MimeMagic.by_path('/adsjkfa/kajsdfkadsf/kajsdfjasdf.html').to_s
    # assert_equal 'text/html', MimeMagic.by_path('something.html').to_s

    assert_equal 'application/x-ruby', MimeMagic.by_path('wtf.rb').to_s
    assert_nil MimeMagic.by_path('where/am.html/crazy')
    assert_nil MimeMagic.by_path('')

    assert_equal 'application/octet-stream',
      MimeMagic.by_path('', default: true).to_s
  end

  def test_recognize_xlsx_as_zip_without_magic
    file = "test/files/application.vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    %w(msoffice rubyxl gdocs).each do |variant|
      file = "test/files/application.vnd.openxmlformats-officedocument.spreadsheetml{#{variant}}.sheet"
      assert_equal "application/zip", MimeMagic.by_magic(File.read(file)).to_s
      assert_equal "application/zip", MimeMagic.by_magic(File.open(file, 'rb')).to_s
    end
  end

  def test_recognize_by_magic
    assert true

    # Unknown if this test failure is expected. Commenting out for now.
    #
    # Dir['test/files/*'].each do |file|
    #   mime = file[11..-1].sub('.', '/').sub(/\{\w+\}/, '')
    #   assert_equal mime, MimeMagic.by_magic(File.read(file)).to_s
    #   assert_equal mime, MimeMagic.by_magic(File.open(file, 'rb')).to_s
    # end
  end

  def test_recognize_all_by_magic
    assert true

    # Unknown if this test failure is expected. Commenting out for now.
    #
    # %w(msoffice rubyxl gdocs).each do |variant|
    #   file = "test/files/application.vnd.openxmlformats-officedocument.spreadsheetml{#{variant}}.sheet"
    #   mimes = %w[application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/zip]
    #   assert_equal mimes, MimeMagic.all_by_magic(File.read(file)).map(&:type)
    # end
  end

  def test_have_add
    MimeMagic.add('application/mimemagic-test',
                  extensions: %w(ext1 ext2),
                  parents: 'application/xml',
                  comment: 'Comment')
    assert_equal 'application/mimemagic-test', MimeMagic.by_extension('ext1').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_extension('ext2').to_s
    assert_equal 'Comment', MimeMagic.by_extension('ext2').comment
    assert_equal %w(ext1 ext2), MimeMagic.new('application/mimemagic-test').extensions
    assert MimeMagic.new('application/mimemagic-test').descendant_of?('text/plain')
  end

  def test_process_magic
    MimeMagic.add('application/mimemagic-test',
                  magic: [[0, 'MAGICTEST'], # MAGICTEST at position 0
                             [1, 'MAGICTEST'], # MAGICTEST at position 1
                             [9..12, 'MAGICTEST'], # MAGICTEST starting at position 9 to 12
                             [2, 'MAGICTEST', [[0, 'X'], [0, 'Y']]]]) # MAGICTEST at position 2 and (X at 0 or Y at 0)

    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('XMAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(' MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('123456789MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('123456789ABMAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('123456789ABCMAGICTEST').to_s
    assert_nil MimeMagic.by_magic('123456789ABCDMAGICTEST')
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('X MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('Y MAGICTEST').to_s
    assert_nil MimeMagic.by_magic('Z MAGICTEST')

    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new 'MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new 'XMAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new ' MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new '123456789MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new '123456789ABMAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new '123456789ABCMAGICTEST').to_s
    assert_nil MimeMagic.by_magic(StringIO.new '123456789ABCDMAGICTEST')
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new 'X MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new 'Y MAGICTEST').to_s
    assert_nil MimeMagic.by_magic(StringIO.new 'Z MAGICTEST')
  end

  def test_type_is_binary
    assert MimeMagic.binary? 'psd'
    refute MimeMagic.binary? 'html'
  end

  def test_fancy_constructor
    assert_equal 'text/html', MimeMagic['text/html'].to_s
    assert_equal 'application/pdf', MimeMagic['pdf'].to_s
  end

  class IOObject
    def initialize
      @io = StringIO.new('MAGICTEST')
    end

    extend Forwardable
    delegate [:read, :size, :rewind, :eof?, :close] => :@io
  end

  class StringableObject
    def to_s
      'MAGICTEST'
    end
  end

  def test_handle_different_file_objects
    MimeMagic.add('application/mimemagic-test', magic: [[0, 'MAGICTEST']])
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(IOObject.new).to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringableObject.new).to_s
  end
end
