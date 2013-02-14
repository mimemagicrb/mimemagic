MimeMagic is a library to detect the mime type of a file by extension or by content.

[![Build Status](https://secure.travis-ci.org/minad/mimemagic.png?branch=master)](http://travis-ci.org/minad/mimemagic) [![Code Climate](https://codeclimate.com/github/minad/mimemagic.png)](https://codeclimate.com/github/minad/mimemagic)

Usage
=====

   require 'mimemagic'
   MimeMagic.by_extension('html').text?
   MimeMagic.by_extension('.html').child_of? 'text/plain'
   MimeMagic.by_path('filename.txt')
   MimeMagic.by_magic(File.open('test.html'))
   etc...

API
===

http://rdoc.info/github/minad/mimemagic/frames/file/README

Authors
=======

Daniel Mendler
