$ ->
  Vue =  require "vue"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  movies = new Ajax "movies"

  # view画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      query:
        skip: 0
        limit: 50
      movies: []
      current: {}
    created: () ->
      # 動画取得
      @getMovies @query
      .then (result) =>
        for val in result
          if val.thumbnail
            imagePath = "/images/#{val.thumnail}/200x200"
          else
            imagePath = "/images/noimage.png"
          @movies.push
            id: val.id
            message: val.message
            imagePath: imagePath
            selected: false
        if @movies.length
          @current = @movies[0]
        return
      .catch (err) ->
        console.log err
        return
      return
    methods:
      # 動画一覧取得Function
      getMovies: (query) ->
        return Promise (resolve, reject) =>
          movies
          .index query
          .then (result) =>
            resolve result
            return
          .catch (err) ->
            console.log err
            reject()
            return
          return
      # List選択
      selectItem: (id) ->
        for val in @movies
          if val.id is id
            val.selected = true
            @current = val
          else
            val.selected = false
        return
  return
