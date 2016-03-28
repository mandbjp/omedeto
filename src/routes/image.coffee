mongo = require "./lib/mongo"
crypto = require "crypto"
fs = require "fs"

# ファイル格納
exports.upload = (req, res) ->
  file = req.files.file
  filePath = file.path
  md5sum = crypto.createHash "md5"
  md5sum.update "#{filePath}"
  fileName = md5sum.digest "hex"

  mongo.writeFile 'img', fileName, filePath, (err, data) ->
    if err
      res.status 500
        .send err
    else
      res.status 200
        .send fileName: fileName
    fs.unlink filePath
    return
  return

# ファイル取得
exports.download = (req, res) ->
  fileName = req.params.fileName

  #res.status 200
  #  .send fileName
  mongo.readFileStream "img", fileName, (err, data) ->
    if err
      res.status 500
        .send err
    else
      res.status 200
        .send data
      return
    return
