mongo = require "./lib/mongo"
fs = require "fs"

# ファイル格納
exports.create = (req, res) ->
  file = req.files.file
  filePath = file.path
  stream = fs.createReadStream filePath

  mongo.insertGridFS 'file', stream, {}
  .then (result) ->
    data =
      fid: result
    res.status 200
      .send data
    fs.unlink filePath
    return
  .catch (err) ->
    res.status 500
      .send err
    return
  return

# ファイル取得
exports.show = (req, res) ->
  _id = req.params.id

  mongo.findGridFS "file", _id, {}
  .then (result) ->
    if result
      data = result.data
    res.status 200
      .send data
    return
  .catch (err) ->
    res.status 500
      .send err
    return
  return
