#!/usr/bin/env ruby

require 'mimemagic/table_generator'

if ARGV.size != 1
  puts "Usage: #{$0} <freedesktop.org.xml>"
  exit 1
end

MimeMagic::TableGenerator.generate(ARGV[0])