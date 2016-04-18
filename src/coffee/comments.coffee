$ ->
  Vue =  require "vue"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  comments = new Ajax "comments"
  db = require "localforage"

  # 検証用コメント画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      nickname: ""
      text: ""
      stamps: ["stamp001.png","stamp002.png"]
    created: () ->
      db.getItem "nickname"
      .then (val) =>
        @nickname = val
        return
      .catch (err) ->
        console.log err
        return
      return
    methods:
      # テキストを送信
      sendText: () ->
        param =
          nickname: @nickname
          text: @text
        @send param
        return

      # スタンプを送信
      sendStamp: (stamp) ->
        param =
          nickname: @nickname
          stamp: stamp
        @send param
        return

      # Comment送信
      send: (param) ->
        comments
        .create param
        .then (result) =>
          @text = ""
          return
        .catch (err) ->
          console.log err
          return
        return
  return
