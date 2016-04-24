mongo = require "./lib/mongo"
Promise = require("q").promise
fs = require "fs"
ffmpeg = require "fluent-ffmpeg"
config = require("./../config").config
child_process = require "child_process"


insertFile = (filePath) ->
  stream = fs.createReadStream filePath
  mongo.insertGridFS config.mongo.filedb, stream, {}

createThumbnail = (filePath) ->
  return Promise (resolve, reject) ->
    thumbnailFilePath = filePath + ".thunmbnail.jpg"
    ffmpeg = child_process.spawn("/usr/bin/ffmpeg", [
      "-i", filePath,
      "-ss", "00:00:01.000",
      "-f", "mjpeg"
      "-vframes", "1",
      thumbnailFilePath
      ]);
    
    ffmpeg.stdout.on "close", () ->
      # file exists check
      # @see http://stackoverflow.com/questions/17699599/node-js-check-exist-file
      
      fs.stat 'foo.txt', (err, stat) ->
        if (err == null)
          # console.log('File exists');
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
  thumbnailFilePath = ""
  data =
    vid: ""
    tid: ""
  
  # 動画ファイルをmongoにinsert
  insertFile filePath
  .then (result) ->
    console.log "[files.create][1/3] video inserted.", result
    data.vid = result
    createThumbnail filePath
    
  # サムネイル画像を生成
  .then (result) ->
    console.log "[files.create][2/3] thumbnail created.", result
    thumbnailFilePath = result
    insertFile thumbnailFilePath
  
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

  mongo.findGridFS config.mongo.filedb, _id, {}
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
