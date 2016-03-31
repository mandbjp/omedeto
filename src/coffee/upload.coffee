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
      message: ""
    created: () ->
      return
    methods:
      # 撮影するボタンクリック
      upload: (e) ->
        fileList = e.target.files
        param = new FormData()
        param.append "file", fileList[0]
        
        @.$http.post "/files", param, {}
        .then (result) =>
          if result.status is 200
            @vid = result.data.fid
            if @vid
              @videoPath = "/files/#{@vid}"
          return
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
