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
            @vid = result.data.vid
            @tid = result.data.tid
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
      
      video_play: () ->
        # 動画が再生された時
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
