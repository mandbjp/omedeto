Vue = require "vue"
db = require "localforage"

module.exports = new Vue
  el: "#top"
  data:
    readed: true
  created: () ->
    db.getItem "manual"
    .then (val) =>
      @readed = if val then val.readed else false
      return
    .catch (err) ->
      console.log err
      return
    return
  methods:
    reload: () ->
      location.href = "/"
      return
    info: () ->
      unless @readed
        manual =
          readed: true
        db.setItem "manual", manual
        @readed = true
      window.open "/manual/omedeto.pdf"
      return
