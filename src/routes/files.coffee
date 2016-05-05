mongo = require "./lib/mongo"
Promise = require("q").promise
fs = require "fs"
config = require("./../config").config
child_process = require "child_process"
ffprobe = require "node-avprobe"


insertFile = (filePath, fileType) ->
  stream = fs.createReadStream filePath
  opt =
    contentType: fileType
  mongo.insertGridFS config.mongo.filedb, stream, opt

# 動画ファイルからサムネイルを作成
createThumbnail = (filePath) ->
  return Promise (resolve, reject) ->
    thumbnailFilePath = filePath + ".thunmbnail.jpg"
    ffmpeg = child_process.spawn("avconv", [
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

# 動画情報を取得
collectVideoInfo = (filePath) ->
  return Promise (resolve, reject) ->
    # ffprobe filePath, (err, probeData) ->
    #   if err
    #     reject "node-ffprobe failed. reason: " + err
        
    #   console.log "---avprobe\n", probeData
    #   # find video stream from response and resolve information
    #   for stream in probeData.streams
    #     if stream.codec_type isnt "video"
    #       continue
    #     calcFramerate = Math.round(eval(stream.avg_frame_rate) * 100) / 100  # calculate equation with eval. eg. 29.95
    #     response = 
    #       file: probeData.file
    #       width: stream.width
    #       height: stream.height
    #       codec_name: stream.codec_name  # video codec name. eg. h264
    #       duration: stream.duration  # video length in second
    #       framerate: calcFramerate
    #     resolve response
    #     return
      
    #   # there is no video stream.
    #   reject "node-ffprobe failed. there is no video stream in file."
    ffmpeg = child_process.spawn("avprobe", [filePath, "-show_streams", "-show_format", "-loglevel", "warning"])

    stdoutData = ""
    ffmpeg.stdout.on "data", (data) ->
      stdoutData += data.toString()

    ffmpeg.stdout.on "close", () ->
      # when ffmpeg is done
      probeData = parseAvprobe stdoutData

      # find video stream from response and resolve information
      for stream in probeData.streams
        if stream.codec_type isnt "video"
          continue
        calcFramerate = Math.round(eval(stream.avg_frame_rate) * 100) / 100  # calculate equation with eval. eg. 29.95
        response = 
          # file: probeData.file
          width: stream.width
          height: stream.height
          codec_name: stream.codec_name  # video codec name. eg. h264
          duration: stream.duration  # video length in second
          framerate: calcFramerate
          rotation: if stream['SIDEDATA:rotation'] then parseInt(stream['SIDEDATA:rotation']) else 0
        resolve response
        return
      
      # there is no video stream.
      reject "avprobe failed. there is no video stream in file."

    ffmpeg.stderr.on "error", () ->
      reject "error on spawning avprobe"
      
    return 

# 動画を圧縮
compressVideo = (filePath, videoInfo) ->
  return Promise (resolve, reject) ->
    # 圧縮後の解像度をターゲット幅から算出する(高さは4の倍数に丸める)
    width = config.video_compression.target_width
    height = multiplesOf(videoInfo.height / (videoInfo.width / config.video_compression.target_width), 4)
    resolution = "#{width}x#{height}"
    if (((Math.abs(videoInfo.rotation) / 90)) % 2) is 1
      # 縦長の動画
      resolution = "#{height}x#{width}"
    
    outputFile = filePath + ".compressed.mp4"
    # command line @see http://tech.ckme.co.jp/ffmpeg.shtml
    ffmpegOptions = [
      "-i", filePath,
      "-b", "#{config.video_compression.bitrate}",  # bitrate as kb/s
      "-r", "#{videoInfo.framerate}",  # framerate to ...
      "-s", resolution,  # resolution to ...
      # "-vcodec", "libx264",  # codec to h264
      # "-vpre", "medium",  # h264 quality
      "-acodec", "copy",  # keep audio as is
      outputFile
      ]
    ffmpeg = child_process.spawn("avconv", ffmpegOptions)
    
    rejectWithLog = (reason) ->
      console.error "ffmpeg response:"
      console.error stdoutData
      console.error "options: ", ffmpegOptions.join " "
      reject reason
    
    ffmpeg.stdout.on "close", () ->
      # when ffmpeg is done
      fs.stat outputFile, (err, stat) ->
        if (err is null) and (stat.size > 0)
          resolve outputFile
        else if (err is null) and (stat.size is 0)
          fs.unlink outputFile
          rejectWithLog "compress video failed. (FileSize is Zero)"
        else if err.code is 'ENOENT'
          rejectWithLog "compress video failed. (ENOENT)"
        else
          reject "compress video failed. (Unknown: #{err.code})"
      
    stdoutData = ""
    ffmpeg.stdout.on "data", (data) ->
      stdoutData += data.toString()

    ffmpeg.stderr.on "error", () ->
      reject "error on spawning ffmpeg for compressVideo"

# 特定の倍数に丸める
multiplesOf = (src, unit) ->
  # @see http://ginpen.com/2011/12/09/floor-to-any/
  return Math.round(src / unit) * unit 

# 
parseAvprobe = (probe) ->
  # required response of 'avprove infile.MOV -show_streams -show_format -loglevel warning' 
  
  # function below originaly from node-ffprove
  parseField = (str) ->
    str = ('' + str).trim()
    if str.match(/^\d+\.?\d*$/) then parseFloat(str) else str

  parseBlock = (block) ->
    block_object = {}
    lines = block.split('\n')
    lines.forEach (line) ->
      data = line.split('=')
      if data and data.length == 2
        block_object[data[0]] = parseField(data[1])
      return
    block_object
  # --
   
  lines = probe.split("\n")
  block = []
  blockName = ""
  blocks = {}
  for line in lines
    if line.match /^\[(.+)\]$/
      block = []
      blockName = line

    else if line.length is 0
      unless blockName is ""
        blocks[blockName.slice(1, blockName.length-1)] = parseBlock(block.join("\n"))
    
    else
      block.push(line);

  format = []
  for key of blocks
    m = key.match /^format.?(.*)/
    unless m
      continue
    # m = ['format.tags', 'tags']
    for k of blocks[key]
      kk = if key.indexOf(".tags") isnt -1 then "TAG:" + k else k
      format[kk] = blocks[key][k]

  streams = []
  for key of blocks
    m = key.match /^streams\.stream.(\d).?(.*)/
    unless m
      continue

    # m = m = ['streams.stream.0.sidedata.displaymatrix', '0', 'sidedata.displaymatrix',]
    index = parseInt m[1]
    if streams[index] is undefined
      streams[index] = {}
    
    for k of blocks[key]
      kk = if key.indexOf(".tags") isnt -1 then "TAG:" + k else 
        if key.indexOf(".sidedata") isnt -1 then "SIDEDATA:" + k else k
      streams[index][kk] = blocks[key][k]
  
  reponse = 
    format: format
    streams: streams
  return reponse
  
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
    console.log "[files.create][1/6] video inserted.", result
    data.vid = result
    collectVideoInfo filePath
    
  # 動画情報取得
  .then (result) ->
    console.log "[files.create][2/6] collectVideoInfo", "#{result.codec_name} #{result.width}x#{result.height}"
    compressVideo filePath, result
    
  # 動画圧縮
  .then (result) ->
    console.log "[files.create][3/6] compressVideo created.", result
    compressVideoPath = result
    compressVideoType = "video/mp4"
    insertFile compressVideoPath, compressVideoType
  
  # 圧縮した動画をmongoにinsert
  .then (result) ->
    console.log "[files.create][4/6] compressVideo inserted."
    data.vid_low = result
    createThumbnail filePath
    
  # サムネイル画像を生成
  .then (result) ->
    console.log "[files.create][5/6] thumbnail created.", result
    thumbnailFilePath = result
    thumbnailFileType = "image/jpeg"
    insertFile thumbnailFilePath, thumbnailFileType
  
  # サムネイルをmongoにinsert
  .then (result) ->
    console.log "[files.create][6/6] thumbnail inserted."
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
