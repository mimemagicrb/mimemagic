MimeMagic is a library to detect the mime type of a file by extension or by content. It uses the mime database
provided by freedesktop.org (see http://freedesktop.org/wiki/Software/shared-mime-info/).

[![Gem Version](https://img.shields.io/gem/v/mimemagic.svg)](http://rubygems.org/gems/mimemagic)

*Warning:* If you are using a version of MimeMagic < 0.3.7, or version 4.0.0, you may well be in breach of the
GPL due to a GPL licensed dependency that was bundled with this gem. You should update to a version >= 0.3.7 
as soon as possible. See https://github.com/minad/mimemagic/issues/97 for details.

Dependencies
============

You will require a copy of the Freedesktop.org shared-mime-types database to be available. If you're on Linux,
it's probably available via your package manager, and will probably be in the location it's being looked for
when the gem is installed.

If you're not on Linux, or for whatever reason the file is found, you'll need to obtain a copy from the Internet.

(TODO: Locate a reliable source for the compiled file, and link to it both here, and in the error message if
one isn't found.)

Usage
=====

```ruby
require 'mimemagic'
MimeMagic.by_extension('html').text?
MimeMagic.by_extension('.html').child_of? 'text/plain'
MimeMagic.by_path('filename.txt')
MimeMagic.by_magic(File.open('test.html'))
# etc...
```

You can add your own magic with `MimeMagic.add`.

API
===

http://www.rubydoc.info/github/minad/mimemagic

Tests
=====

```
bundle install

rake test
```

Authors
=======

Daniel Mendler

LICENSE
=======

MIT
