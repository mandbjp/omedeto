mongo = require "./lib/mongo"
Promise = require("q").promise
fs = require "fs"
ffmpeg = require "fluent-ffmpeg"

insertFile = (filePath) ->
  stream = fs.createReadStream filePath
  mongo.insertGridFS 'file', stream, {}

createThumbnail = (filePath) ->
  return Promise (resolve, reject) ->
    uploadDir = "upload"  # should end without slash
    thumbnailFilePath = ""
    command = ffmpeg filePath
    opt = 
      filename: "%b.thunmbnail.png"
      folder: uploadDir
      timemarks: ["1"]
      
    command
    .on "filenames", (filenames) ->
      thumbnailFilePath = uploadDir + "/" + filenames[0]
    .on "end", () ->
      resolve thumbnailFilePath
    .on "error", (err) ->
      reject err.message
    .screenshots opt

# ファイル格納
exports.create = (req, res) ->
  file = req.files.file
  filePath = file.path
  thumbnailFilePath = ""
  data = 
    vid: ""
    tid: ""
  
  # 動画ファイルをmongoにinsert
  insertFile filePath
  .then (result) ->
    data.vid = result
    createThumbnail filePath
    
  # サムネイル画像を生成
  .then (result) ->
    thumbnailFilePath = result
    insertFile thumbnailFilePath
  
  # サムネイルをmongoにinsert
  .then (result) ->
    data.tid = result
    return
    
  # ユーザーにレスポンスを返す
  .then () ->
    res.status 200
      .send data
    fs.unlink filePath
    fs.unlink thumbnailFilePath
    return
    
  # エラーレスポンス
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
