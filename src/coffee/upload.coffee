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
      thumbnail: ""
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
            fileName = result.data.fileName
            if fileName
              @videoPath = "/files/#{fileName}"
          return
        return

      # 送るボタンクリック
      send: () ->
        param =
          thumbnail: @thumbnail
          message: @message

        movies
        .create param
        .then (result) =>
          if result.length
            alert "ご協力ありがとうございます。"
          return
        .catch (err) ->
          console.log err
          return
        return
  return
