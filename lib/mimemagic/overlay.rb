# Extra magic

[['application/vnd.openxmlformats-officedocument.presentationml.presentation', [[0..2000, 'ppt/']]],
 ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', [[0..2000, 'xl/']]],
 ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', [[0..2000, 'word/']]]].each do |magic|
  MimeMagic.add(magic[0], magic: magic[1])
end
