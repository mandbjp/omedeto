Vue = require "vue"

module.exports = new Vue
  el: "#top"
  methods:
    reload: () ->
      location.href = "/"
      return
