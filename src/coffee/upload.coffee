$ ->
  Vue =  require "vue"
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
      $("#upload").fileupload
        done: (e, result) =>
          fileName = result.jqXHR.responseJSON.fileName
          @thumbnail = fileName
          @videoPath = "/files/#{fileName}"
          return
        fail: (e, data) ->
          console.log e
          return
      return
    methods:
      upload: (e) ->
        fileList = e.target.files
        param = new FormData()
        param.append "file", fileList[0]
        
        files
        .create param
        .then (result) =>
          console.log result
          return
        .catch (err) ->
          console.log err
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
