require 'mimemagic'

class TC_MimeMagic < Test::Unit::TestCase
  def test_text?
    assert MimeMagic.new('text/plain').text?
    assert MimeMagic.new('text/html').text?
    assert !MimeMagic.new('application/octet-stream').text?
    assert !MimeMagic.new('image/png').text?
  end

  def test_child_of?
    assert MimeMagic.new('text/html').child_of?('text/plain')
    assert MimeMagic.new('text/x-java').child_of?('text/plain')
  end

  def test_extensions
    assert_equal %w(htm html), MimeMagic.new('text/html').extensions
  end

  def test_by_extension
    assert_equal 'text/html', MimeMagic.by_extension('html').to_s
    assert_equal 'application/x-ruby', MimeMagic.by_extension('rb').to_s
    assert_nil MimeMagic.by_extension('crazy')
    assert_nil MimeMagic.by_extension('')
  end

  def test_by_magic
    assert_equal 'application/x-executable', MimeMagic.by_magic(File.open('/bin/ls')).to_s
    assert_equal 'application/x-sharedlib', MimeMagic.by_magic(File.open('/lib/libc.so.6')).to_s
  end
end
