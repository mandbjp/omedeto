$ ->
  Vue =  require "vue"
  Vue.use require "vue-resource"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  db = require "localforage"
  files = new Ajax "files"
  videos = new Ajax "videos"
  require "./lib/header"

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
      viewShowVideoUploading: false
      viewShowFileSelect: true
      viewShowVideoPreview: false
      viewSendButtonText: "登録する"

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
        if fileList.length
          @viewShowFileSelect = false
          @viewShowVideoPreview = true
          @viewShowVideoUploading = true

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
            if result.status is 200
              @vid = result.data.vid
              @tid = result.data.tid
              if @vid
                @viewShowVideoUploading = false
                @viewSendBtnDissabled = false
            return
          .catch (err) ->
            console.log "error on video upload", err
            return
        return
          
      video_play: () ->
        # 動画が再生された時
        return

      # 送るボタンクリック
      send: () ->
        if @vid.length is 0
          alert "読み込みが完了するまで待ってください！"
          return
        if confirm("この動画を登録しますか？\n\n注意: 動画を登録すると自分では削除できません!")
          param =
            vid: @vid
            tid: @tid
            nickname: @nickname

          videos
          .create param
          .then (result) =>
            if result.ok
              @viewSendButtonText = "登録しました！"
              @viewSendBtnDissabled = true
              alert "動画を登録しました。\n\nご協力ありがとうございます。"
              location.href = "/"
            return
          .catch (err) ->
            console.log err
            return
        return
  return
