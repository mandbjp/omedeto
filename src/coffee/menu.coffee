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
      return
    methods:
      selectMenu: (view) ->
        if @nickname
          db.setItem "nickname", @nickname
        location.href = "/#{view}"
        return
  return
