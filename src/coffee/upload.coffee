$ ->
  Vue =  require "vue"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  movies = new Ajax "movies"

  # upload画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      imagePath: ""
      thumbnail: ""
      message: ""
    created: () ->
      @imagePath = "/images/noimage.png"

      $("#upload").fileupload
        done: (e, result) =>
          fileName = result.jqXHR.responseJSON.fileName
          console.log fileName
          @thumbnail = fileName
          @imagePath = "/images/#{fileName}/120x120"
          return
        fail: (e, data) ->
          console.log e
          return
      return
    methods:
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
