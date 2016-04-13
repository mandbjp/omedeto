$ ->
  Vue = require "vue"
  db = require "localforage"

  # menu画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      nickname: ""
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
      # ニックネーム設定
      setNickname: () ->
        if @nickname
          db.setItem "nickname", @nickname
        return
      # メニュー選択
      selectMenu: (view) ->
        location.href = "/#{view}"
        return
  return
