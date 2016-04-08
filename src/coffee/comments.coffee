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
      content: ""
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
      # 送るボタンクリック
      send: () ->
        param =
          nickname: @nickname
          content: @content

        comments
        .create param
        .then (result) =>
          @content = ""
          return
        .catch (err) ->
          console.log err
          return
        return
  return
