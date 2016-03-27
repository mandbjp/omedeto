$ ->
  Vue =  require "vue"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise

  # upload画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      imagePath: ""
      message: ""
    created: () ->
      @imagePath = "/images/noimage.png"
      return
  return
