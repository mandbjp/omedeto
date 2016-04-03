$ ->
  Vue =  require "vue"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  comments = new Ajax "comments"

  # 検証用コメント画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      nickname: ""
      content: ""
    created: () ->
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
          console.log result
          return
        .catch (err) ->
          console.log err
          return
        return
  return
