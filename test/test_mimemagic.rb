gem 'test-unit', '>= 0'
gem 'test-spec', '>= 0'
require 'test/unit'
require 'test/spec'
require 'mimemagic'

describe 'MimeMagic' do
  it 'should have text? helper' do
    MimeMagic.new('text/plain').should.be.text
    MimeMagic.new('text/html').should.be.text
    MimeMagic.new('application/octet-stream').should.be.not.text
    MimeMagic.new('image/png').should.be.not.text
  end
  it 'should have hierarchy' do
    MimeMagic.new('text/html').should.be.child_of 'text/plain'
    MimeMagic.new('text/x-java').should.be.child_of 'text/plain'
  end

  it 'should have extensions' do
    MimeMagic.new('text/html').extensions.should == %w(htm html)
  end

  it 'should recognize extensions' do
    MimeMagic.by_extension('html').to_s.should == 'text/html'
    MimeMagic.by_extension('rb').to_s.should == 'application/x-ruby'
    MimeMagic.by_extension('crazy').should == nil
    MimeMagic.by_extension('').should == nil
  end

  it 'should recognize by magic' do
    MimeMagic.by_magic(File.open('/bin/ls')).to_s.should == 'application/x-executable'
    MimeMagic.by_magic(File.open('/lib/libc.so.6')).to_s.should == 'application/x-sharedlib'
  end
end
