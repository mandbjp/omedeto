$ ->
  Vue =  require "vue"
  Vue.use require "vue-resource"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  files = new Ajax "files"
  movies = new Ajax "movies"

  # upload画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      videoPath: ""
      fid: ""
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
            @fid = result.data.fid
            if @fid
              @videoPath = "/files/#{@fid}"
          return
        return

      # 送るボタンクリック
      send: () ->
        param =
          fid: @fid
          message: @message

        movies
        .create param
        .then (result) =>
          console.log result
          if result.ok
            alert "ご協力ありがとうございます。"
          return
        .catch (err) ->
          console.log err
          return
        return
  return
