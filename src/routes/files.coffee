mongo = require "./lib/mongo"
Promise = require("q").promise
fs = require "fs"
config = require("./../config").config
child_process = require "child_process"


insertFile = (filePath, fileType) ->
  stream = fs.createReadStream filePath
  opt =
    contentType: fileType
  mongo.insertGridFS config.mongo.filedb, stream, opt


createThumbnail = (filePath) ->
  return Promise (resolve, reject) ->
    thumbnailFilePath = filePath + ".thunmbnail.jpg"
    ffmpeg = child_process.spawn("ffmpeg", [
      "-i", filePath,
      "-ss", "00:00:00.500",
      "-f", "mjpeg"
      "-vframes", "1",
      thumbnailFilePath
      ])
    
    ffmpeg.stdout.on "close", () ->
      # file exists check
      # @see http://stackoverflow.com/questions/17699599/node-js-check-exist-file
      fs.stat thumbnailFilePath, (err, stat) ->
        if (err == null)
          resolve thumbnailFilePath
        else if err.code == 'ENOENT'
          reject "thumbnail creation failed. (ENOENT)"
        else
          reject "thumbnail creation failed. (Unknown: " + err.code + ")"
      
    ffmpeg.stderr.on "error", () ->
      reject "error on spawning ffmpeg"

# ファイル格納
exports.create = (req, res) ->
  file = req.files.file
  filePath = file.path
  fileType = file.type
  thumbnailFilePath = ""
  data =
    vid: ""
    tid: ""
  
  # 動画ファイルをmongoにinsert
  insertFile filePath, fileType
  .then (result) ->
    console.log "[files.create][1/3] video inserted.", result
    data.vid = result
    createThumbnail filePath
    
  # サムネイル画像を生成
  .then (result) ->
    console.log "[files.create][2/3] thumbnail created.", result
    thumbnailFilePath = result
    thumbnailFileType = "image/jpeg"
    insertFile thumbnailFilePath, thumbnailFileType
  
  # サムネイルをmongoにinsert
  .then (result) ->
    console.log "[files.create][3/3] thumbnail inserted."
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
    console.log "[files.create][ERROR]", err
    res.status 500
      .send err
    return
  return
  
# ファイル取得
exports.show = (req, res) ->
  _id = req.params.id
  query = req.query
  type = query.type
  opt =
    verbose: true

  mongo.findGridFS config.mongo.filedb, _id, opt
  .then (result) ->
    if result
      option = result.option
      contentType = option.contentType
      length = option.length
      data = result.data
      if type is "video"
        data = new Buffer(data).toString('base64')
        contentType = contentType ? "video/mp4"
        res.set
          "Content-Type": "#{contentType}; charset=utf-8"
          "Accept-Ranges": "bytes"
          "Content-Length": length
      res.status 200
        .send data
    return
  .catch (err) ->
    res.status 500
      .send err
    return
  return
