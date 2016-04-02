$ ->
  Vue =  require "vue"
  Vue.use require "vue-resource"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  files = new Ajax "files"
  videos = new Ajax "videos"

  # upload画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      videoPath: ""
      vid: ""
      tid: ""
      message: ""
    created: () ->
      return
    methods:
      # 撮影するボタンクリック
      upload: (e) ->
        fileList = e.target.files

        # canvasの画像データをblob形式に変換する
        # @see http://qiita.com/0829/items/a8c98c8f53b2e821ac94
        canvasToBlob = (canvas) ->
          type = 'image/png'
          base64 = canvas.toDataURL type
          # Base64からバイナリへ変換
          bin = atob(base64.replace(/^.*,/, ''));
          buffer = new Uint8Array(bin.length);
          for b, i in bin
            buffer[i] = bin.charCodeAt i
          # Blobを作成
          blob = new Blob [buffer.buffer], {type: type};
          return blob
          
        # クライアントサイドのみで動画を再生する
        # @see http://jsfiddle.net/Ronny/P2NpU/
        URL = window.URL || window.webkitURL
        if (!URL)
          alert "your browser not supported for preview"
          return
        videoNode = document.querySelector 'video'
        local_blob = URL.createObjectURL fileList[0]
        videoNode.src = local_blob
        videoNode.play()
        
        # canvasに貼り付けて静止画を取得する
        thumbnailPromise = new Promise (resolve) ->
          setTimeout () ->
            videoNode = document.querySelector 'video'
            videoNode.pause()
            canvasNode = document.querySelector 'canvas'
            canvasContext = canvasNode.getContext '2d'
            canvasNode.style = "height:" + videoNode.videoHeight + "px; width: " + videoNode.videoWidth + "px;";
            vw = videoNode.videoWidth / 2
            vh = videoNode.videoHeight / 2
            canvasNode.width = vw
            canvasNode.height = vh
            canvasContext.drawImage videoNode, 0, 0, vw, vh
            resolve canvasNode
          , 100
        
        thumbnailPromise.then (canvasNode) ->
          blob = canvasToBlob canvasNode
          blobUrl = URL.createObjectURL blob
          console.log blobUrl
          
        # TODO: videoとthumbnailをアップロードする
        
        # param = new FormData()
        # param.append "file", fileList[0]
        # @.$http.post "/files", param, {}
        # .then (result) =>
        #   if result.status is 200
        #     @vid = result.data.fid
        #     if @vid
        #       @videoPath = "/files/#{@vid}"
        #   return
        return

      # 送るボタンクリック
      send: () ->
        param =
          vid: @vid
          message: @message

        videos
        .create param
        .then (result) =>
          if result.ok
            alert "ご協力ありがとうございます。"
          return
        .catch (err) ->
          console.log err
          return
        return
  return
