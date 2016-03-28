$ ->
  Vue =  require "vue"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  movies = new Ajax "movies"
  primus = new Primus("/primus")

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
      room =
        sid: "omedeto"
      @connectWS room
      # 動画取得
      @getMovies @query
      .then (result) =>
        for val in result
          if val.thumbnail
            imagePath = "/images/#{val.thumbnail}/200x200"
          else
            imagePath = "/images/noimage.png"
          @movies.push
            _id: val._id
            message: val.message
            imagePath: imagePath
            selected: false
        if @movies.length
          @selectItem @movies[0]._id
        return
      .catch (err) ->
        console.log err
        return
      return
    methods:
      # 動画一覧取得
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

      # 動画情報取得
      getMovie: (id) ->
        return Promise (resolve, reject) =>
          movies
          .show id
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
          if val._id is id
            val.selected = true
            @current = val
          else
            val.selected = false
        return

      # WebSocket接続
      connectWS: (room) ->
        primus.write room
        primus.on "data", (data) =>
          if data._id
            @getMovie data._id
            .then (result) =>
              if result
                if result.thumbnail
                  imagePath = "/images/#{result.thumbnail}/200x200"
                else
                  imagePath = "/images/noimage.png"

                @movies.push
                  _id: result._id
                  message: result.message
                  imagePath: imagePath
                  selected: false
              return
            .catch (err) ->
              console.log err
              return
          return
        return
  return
