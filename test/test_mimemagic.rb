gem 'bacon', '>= 0'

require 'bacon'
require 'mimemagic'

describe 'MimeMagic' do
  it 'should have mediatype helpers' do
    MimeMagic.new('text/plain').should.be.text
    MimeMagic.new('text/html').should.be.text
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

  it 'should recognize extensions' do
    MimeMagic.by_extension('html').to_s.should.equal 'text/html'
    MimeMagic.by_extension('rb').to_s.should.equal 'application/x-ruby'
    MimeMagic.by_extension('crazy').should.equal nil
    MimeMagic.by_extension('').should.equal nil
  end

  it 'should recognize by magic' do
    Dir['test/files/*'].each do |file|
      mime = file[11..-1].gsub('.', '/')
      MimeMagic.by_magic(File.read(file)).to_s.should.equal mime
      MimeMagic.by_magic(File.open(file, 'rb')).to_s.should.equal mime
    end
  end

  it 'should have add' do
    MimeMagic.add('application/mimemagic-test', %w(ext1 ext2), %w(application/xml))
    MimeMagic.by_extension('ext1').to_s.should.equal 'application/mimemagic-test'
    MimeMagic.by_extension('ext2').to_s.should.equal 'application/mimemagic-test'
    MimeMagic.new('application/mimemagic-test').extensions.should.equal %w(ext1 ext2)
    MimeMagic.new('application/mimemagic-test').should.be.child_of 'text/plain'
  end
end
