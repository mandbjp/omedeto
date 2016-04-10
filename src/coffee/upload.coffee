$ ->
  Vue =  require "vue"
  Vue.use require "vue-resource"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  db = require "localforage"
  files = new Ajax "files"
  videos = new Ajax "videos"

  # upload画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      videoPath: ""
      imagePath: ""
      vid: ""
      tid: ""
      nickname: ""
      selectedFile: null
      message: ""
      viewSendBtnDissabled: true
      viewThumbnailUploadTriggered: false
      viewShowFileSelect: true
      viewShowVideoPreview: false
    created: () ->
      db.getItem "nickname"
      .then (val) =>
        @nickname = val
        return
      return

    methods:
      # 撮影するボタンクリック
      upload: (e) ->
        fileList = e.target.files
        @viewShowFileSelect = false
        @viewShowVideoPreview = true

        # クライアントサイドのみで動画を再生する
        # @see http://jsfiddle.net/Ronny/P2NpU/
        URL = window.URL || window.webkitURL
        if (!URL)
          alert "your browser not supported for preview"
          return
        @selectedFile = fileList[0]
        @videoPath = URL.createObjectURL @selectedFile

        # Videoのアップロード
        param = new FormData()
        param.append "file", @selectedFile
        @.$http.post "/files", param, {}
        .then (result) =>
          console.log "video sent"
          if result.status is 200
            @vid = result.data.fid
            if @vid
              # @videoPath = "/files/#{@vid}"  # アップロードした動画をロードする必要はあるか？
              @viewSendBtnDissabled = false
          return
        .catch (err) ->
          console.log "error on video upload", err
          return
        return
          
      confirmAndReloadPage: () ->
        if confirm("もう一度動画を選択しますか？")
          window.location.reload()    # reload() でDOMや変数初期化、ajax通信などもキャンセル
        
        return
      
      # canvasの画像データをblob形式に変換する
      # @see http://qiita.com/0829/items/a8c98c8f53b2e821ac94
      canvasToBlob: (canvas) ->
        type = 'image/jpeg'
        base64 = canvas.toDataURL type
        # Base64からバイナリへ変換
        bin = atob(base64.replace(/^.*,/, ''));
        buffer = new Uint8Array(bin.length);
        for b, i in bin
          buffer[i] = bin.charCodeAt i
        # Blobを作成
        blob = new Blob [buffer.buffer], {type: type};
        return blob

      video_play: () ->
        # 動画が再生された時
        console.log "play"
        
        if @viewThumbnailUploadTriggered
          return
        Q.Promise (resolve, reject) =>
          # canvasに貼り付けて静止画を取得する
          setTimeout () =>
            videoNode = document.querySelector 'video'
            canvasNode = document.querySelector 'canvas'
            canvasContext = canvasNode.getContext '2d'
            canvasNode.style = "height:" + videoNode.videoHeight + "px; width: " + videoNode.videoWidth + "px;";
            vw = videoNode.videoWidth / 2
            vh = videoNode.videoHeight / 2
            canvasNode.width = vw
            canvasNode.height = vh
            canvasContext.drawImage videoNode, 0, 0, vw, vh
            resolve canvasNode
          , 1000 # ms

        .then (canvasNode) =>
          # サムネイルをアップロードする
          thumbnailBlob = @canvasToBlob canvasNode
          @viewThumbnailUploadTriggered = true

          thumbnailParam = new FormData()
          thumbnailParam.append "file", thumbnailBlob
          @.$http.post "/files", thumbnailParam, {}
          .then (result) =>
            console.log "thumnail sent"
            if result.status is 200
              @tid = result.data.fid
              if @tid
                @imagePath = "/files/#{@tid}"
            return
          .catch (err) ->
            console.log "error on thumbnail upload", err
            return
          return

        .catch (err) ->
          console.log "error on thumbnailPromise upload", err
          return

      # 送るボタンクリック
      send: () ->
        if @vid.length is 0
          alert "アップロードが完了するまで待ってください！"
          return
        param =
          vid: @vid
          tid: @tid
          nickname: @nickname

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
