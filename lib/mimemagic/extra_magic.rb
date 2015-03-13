class MimeMagic
  # The freedesktop.org magic tables don't handle .xlsx, .pptx, or
  # .docx files. These magic ranges are too large for them to accept
  # (https://bugs.freedesktop.org/show_bug.cgi?id=78797).
  #
  EXTRA_MAGIC = [
    ['application/vnd.openxmlformats-officedocument.presentationml.presentation', [[0..2000, 'ppt/']]],
    ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', [[0..2000, 'xl/']]],
    ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', [[0..2000, 'word/']]]
  ]

  MAGIC = EXTRA_MAGIC + AUTO_MAGIC
end
