require 'bacon'
require 'mimemagic'

describe 'MimeMagic' do
  it 'should have type, mediatype and subtype' do
    MimeMagic.new('text/html').type.should.equal 'text/html'
    MimeMagic.new('text/html').mediatype.should.equal 'text'
    MimeMagic.new('text/html').subtype.should.equal 'html'
  end

  it 'should have mediatype helpers' do
    MimeMagic.new('text/plain').should.be.text
    MimeMagic.new('text/html').should.be.text
    MimeMagic.new('application/xhtml+xml').should.be.text
    MimeMagic.new('application/octet-stream').should.not.be.text
    MimeMagic.new('image/png').should.not.be.text
    MimeMagic.new('image/png').should.be.image
    MimeMagic.new('video/ogg').should.be.video
    MimeMagic.new('audio/mpeg').should.be.audio
  end

  it 'should have hierarchy' do
    MimeMagic.new('text/html').should.be.child_of 'text/plain'
    MimeMagic.new('text/x-java').should.be.child_of 'text/plain'
  end

  it 'should have extensions' do
    MimeMagic.new('text/html').extensions.should.equal %w(htm html)
  end

  it 'should have comment' do
    MimeMagic.new('text/html').comment.should.equal 'HTML document'
  end

  it 'should recognize extensions' do
    MimeMagic.by_extension('.html').should.equal 'text/html'
    MimeMagic.by_extension('html').should.equal 'text/html'
    MimeMagic.by_extension(:html).should.equal 'text/html'
    MimeMagic.by_extension('rb').should.equal 'application/x-ruby'
    MimeMagic.by_extension('crazy').should.equal nil
    MimeMagic.by_extension('').should.equal nil
  end

  it 'should recognize by a path' do
    MimeMagic.by_path('/adsjkfa/kajsdfkadsf/kajsdfjasdf.html').should.equal 'text/html'
    MimeMagic.by_path('something.html').should.equal 'text/html'
    MimeMagic.by_path('wtf.rb').should.equal 'application/x-ruby'
    MimeMagic.by_path('where/am.html/crazy').should.equal nil
    MimeMagic.by_path('').should.equal nil
  end

  it 'should recognize by magic' do
    Dir['test/files/*'].each do |file|
      mime = file[11..-1].gsub('.', '/')
      MimeMagic.by_magic(File.read(file)).should.equal mime
      MimeMagic.by_magic(File.open(file, 'rb')).should.equal mime
    end
  end

  it 'should have add' do
    MimeMagic.add('application/mimemagic-test',
                  :extensions => %w(ext1 ext2),
                  :parents => 'application/xml',
                  :comment => 'Comment')
    MimeMagic.by_extension('ext1').should.equal 'application/mimemagic-test'
    MimeMagic.by_extension('ext2').should.equal 'application/mimemagic-test'
    MimeMagic.by_extension('ext2').comment.should.equal 'Comment'
    MimeMagic.new('application/mimemagic-test').extensions.should.equal %w(ext1 ext2)
    MimeMagic.new('application/mimemagic-test').should.be.child_of 'text/plain'
  end

  it 'should process magic' do
    MimeMagic.add('application/mimemagic-test',
                  :magic => [[0, 'MAGICTEST'], # MAGICTEST at position 0
                             [1, 'MAGICTEST'], # MAGICTEST at position 1
                             [2, 'MAGICTEST', [[0, 'X'], [0, 'Y']]]]) # MAGICTEST at position 2 and (X at 0 or Y at 0)

    MimeMagic.by_magic('MAGICTEST').should.equal 'application/mimemagic-test'
    MimeMagic.by_magic('XMAGICTEST').should.equal 'application/mimemagic-test'
    MimeMagic.by_magic(' MAGICTEST').should.equal 'application/mimemagic-test'
    MimeMagic.by_magic('X MAGICTEST').should.equal 'application/mimemagic-test'
    MimeMagic.by_magic('Y MAGICTEST').should.equal 'application/mimemagic-test'
    MimeMagic.by_magic('Z MAGICTEST').should.equal nil
  end

  it 'should handle different file objects' do
    MimeMagic.add('application/mimemagic-test', :magic => [[0, 'MAGICTEST']])
    class ReadableObj
      def read
        'MAGICTEST'
      end
    end
    MimeMagic.by_magic(ReadableObj.new).should.equal 'application/mimemagic-test'
    class StringableObject
      def to_s
        'MAGICTEST'
      end
    end
    MimeMagic.by_magic(StringableObject.new).should.equal 'application/mimemagic-test'
  end
end
