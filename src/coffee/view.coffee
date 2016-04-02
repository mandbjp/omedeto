$ ->
  Vue =  require "vue"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  videos = new Ajax "videos"
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
      videos: []
      current: {}
    created: () ->
      room =
        sid: "omedeto"
      @connectWS room
      # 動画取得
      @getVideos @query
      .then (result) =>
        for val in result
          if val.tid
            imagePath = "/files/#{val.tid}/200x200"
          else
            imagePath = "/images/noimage.png"
          unless val.nickname
            val.nickname = "不明"

          @videos.push
            _id: val._id
            nickname: val.nickname
            imagePath: imagePath
            vid: val.vid
            videoPath: ""
            selected: false
            positionX: ""
            positionY: ""

        if @videos.length
          @selectItem @videos[0]._id
        return
      .catch (err) ->
        console.log err
        return
      return
    methods:
      # 動画一覧取得
      getVideos: (query) ->
        return Promise (resolve, reject) =>
          videos
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
      getVideo: (id) ->
        return Promise (resolve, reject) =>
          videos
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
        for val in @videos
          if val._id is id
            val.selected = true
            @current = val
            val.videoPath = "/files/#{val.vid}"
          else
            val.selected = false
        return

      # WebSocket接続
      connectWS: (room) ->
        primus.write room
        primus.on "data", (data) =>
          console.log data
          if data.vid
            query =
              sid: "omedeto"
              vid: data.vid

            @getVideos query
            .then (result) =>
              if result.length
                result = result[0]
                if result.tid
                  imagePath = "/files/#{result.tid}/200x200"
                else
                  imagePath = "/images/noimage.png"

                unless result.nickname
                  result.nickname = "不明"

                @videos.push
                  _id: result._id
                  nickname: result.nickname
                  imagePath: imagePath
                  vid: result.vid
                  videoPath: ""
                  selected: false
              return
            .catch (err) ->
              console.log err
              return
          return
        return
  return
