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
    thumbnailFilePath = filePath + ".thunmbnail.png"
    # outputStream = fs.createWriteStream thumbnailFilePath

    console.log "createThumbnail", 0
    console.log "createThumbnail", 0, filePath
    console.log "createThumbnail", 0, thumbnailFilePath
    ffmpeg = child_process.spawn("/usr/bin/ffmpeg", [
      "-i", filePath,
      "-ss", "00:00:01.000",
      "-vframes", "1",
      thumbnailFilePath
      ]);
    console.log "createThumbnail", 1
    
    ffmpeg.stdout.on "close", () ->
      console.log "createThumbnail", 3, "stdout close"
      resolve thumbnailFilePath
    console.log "createThumbnail", 2
    
    # ffmpeg.stderr.on "data", () ->
    #   console.log "createThumbnail", 4, "data"
    # console.log "createThumbnail", 22
    
    # ffmpeg.stderr.on "exit", () ->
    #   console.log "createThumbnail", 6, "exit"
    # ffmpeg.stderr.on "close", () ->
    #   console.log "createThumbnail", 7, "stderr close"
    #   resolve thumbnailFilePath
    # ffmpeg.stderr.on "error", () ->
    #   reject "error on spawning ffmpeg"

    console.log "createThumbnail", 3
    
    # uploadDir = "upload"  # should end without slash
    # thumbnailFilePath = ""
    # console.log "createThumbnail", 1
    # command = ffmpeg filePath
    # console.log "createThumbnail", 2, command
    # opt =
    #   filename: "%b.thunmbnail.png"
    #   folder: uploadDir
    #   timemarks: ["1"]
      
    # command
    # .on "filenames", (filenames) ->
    #   console.log "createThumbnail", 3, "filenames", filenames
    #   thumbnailFilePath = uploadDir + "/" + filenames[0]
    # .on "end", () ->
    #   console.log "createThumbnail", 4, "end"
    #   resolve thumbnailFilePath
    # .on "error", (err) ->
    #   console.log "createThumbnail", 5, "error", err
    #   reject err.message
    # .screenshots opt
    # console.log "createThumbnail", 9

# ファイル格納
exports.create = (req, res) ->
  file = req.files.file
  filePath = file.path
  thumbnailFilePath = ""
  data =
    vid: ""
    tid: ""
  
  console.log "create then", 0
  # 動画ファイルをmongoにinsert
  insertFile filePath
  .then (result) ->
    console.log "create then", 1, result
    data.vid = result
    createThumbnail filePath
    
  # サムネイル画像を生成
  .then (result) ->
    console.log "create then", 2, result
    thumbnailFilePath = result
    insertFile thumbnailFilePath
  
  # サムネイルをmongoにinsert
  .then (result) ->
    console.log "create then", 3, result
    data.tid = result
    return
    
  # ユーザーにレスポンスを返す
  .then () ->
    console.log "create then", 4
    res.status 200
      .send data
    fs.unlink filePath
    fs.unlink thumbnailFilePath
    return
    
  # エラーレスポンス
  .catch (err) ->
    console.log "create catch", 3, err
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
