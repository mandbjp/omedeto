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

# 動画ファイルからサムネイルを作成
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

# 動画を圧縮
compressVideo = (filePath) ->
  return Promise (resolve, reject) ->
    outputFile = filePath + ".compressed.mp4"  # output format is 'mp4'
    # command line @see http://tech.ckme.co.jp/ffmpeg.shtml
    ffmpeg = child_process.spawn("ffmpeg", [
      "-i", filePath,
      "-vf", "scale=640:-1",  # resize video to 640:x 
      outputFile
      ])
    
    ffmpeg.stdout.on "close", () ->
      # when ffmpeg is done
      fs.stat outputFile, (err, stat) ->
        if (err is null) and (stat.size > 0)
          resolve outputFile
        else if (err is null) and (stat.size is 0)
          fs.unlink outputFile
          reject "compress video failed. (FileSize is Zero)"
        else if err.code is 'ENOENT'
          reject "compress video failed. (ENOENT)"
        else
          reject "compress video failed. (Unknown: #{err.code})"
      
    ffmpeg.stderr.on "error", () ->
      reject "error on spawning ffmpeg for compressVideo"

# ファイル格納
exports.create = (req, res) ->
  file = req.files.file
  filePath = file.path
  fileType = file.type
  thumbnailFilePath = ""
  compressVideoPath = ""
  data =
    vid: ""
    vid_low: ""
    tid: ""
  
  # 動画ファイルをmongoにinsert
  insertFile filePath, fileType
  .then (result) ->
    console.log "[files.create][1/5] video inserted.", result
    data.vid = result
    compressVideo filePath
    
  # 動画圧縮
  .then (result) ->
    console.log "[files.create][2/5] compressVideo created.", result
    compressVideoPath = result
    compressVideoType = "video/mp4"
    insertFile compressVideoPath, compressVideoType
  
  # 圧縮した動画をmongoにinsert
  .then (result) ->
    console.log "[files.create][3/5] compressVideo inserted."
    data.vid_low = result
    createThumbnail filePath
    
  # サムネイル画像を生成
  .then (result) ->
    console.log "[files.create][4/5] thumbnail created.", result
    thumbnailFilePath = result
    thumbnailFileType = "image/jpeg"
    insertFile thumbnailFilePath, thumbnailFileType
  
  # サムネイルをmongoにinsert
  .then (result) ->
    console.log "[files.create][5/5] thumbnail inserted."
    data.tid = result
    return
    
  # ユーザーにレスポンスを返す
  .then () ->
    res.status 200
      .send data
    fs.unlink filePath
    fs.unlink thumbnailFilePath
    fs.unlink compressVideoPath
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
