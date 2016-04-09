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
      currentVid: ""
      comments: []
    created: () ->
      room =
        sid: "omedeto"
      @connectWS room
      # 動画取得
      @getVideos @query
      .then (result) =>
        for val in result
          if val.tid
            imagePath = "/files/#{val.tid}"
          else
            imagePath = "/images/noimage.png"

          if val.vid
            videoPath = "/files/#{val.vid}"
 
          unless val.nickname
            val.nickname = "不明"

          @videos.push
            _id: val._id
            nickname: val.nickname
            imagePath: imagePath
            vid: val.vid
            videoPath: videoPath
            selected: false
            positionX: ""
        
        # 初期表示時、先頭の動画選択
        if @videos.length
          setTimeout () =>
            @selectItem @videos[0]._id
            return
          , 1000
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

      # Metadataローディング後、再生
      loadedmetadata: (e) ->
        vid = e.target.id
        if vid
          $("##{vid}").get(0).play()
        return

      # 動画再生完了イベント
      ended: (e) ->
        endedID = e.target.id
        for val, index in @videos
          if val.vid is endedID
            next = index + 1
            if next >= @videos.length
              next = 0
            # 次の動画を選択
            @selectItem @videos[next]._id
        return
      
      # List選択
      selectItem: (id) ->
        for val, index in @videos
          if val._id is id
            if @currentVid
              # 既存動画停止
              $("##{@currentVid}").get(0).pause()
            val.selected = true
            val.videoPath = "/files/#{val.vid}"
            width = $(window).width()

            # 選択動画の位置にスクロール移動
            $("#view").animate
              scrollLeft: (width * index)

            # 選択動画ローディング
            $("##{val.vid}").get(0).load()
            @currentVid = val.vid
          else
            val.selected = false
        return

      # WebSocket接続
      connectWS: (room) ->
        primus.write room
        primus.on "data", (data) =>
          if data.type is "video"
            if data._id
              @getVideo data._id
              .then (result) =>
                if result
                  if result.tid
                    imagePath = "/files/#{result.tid}"
                  else
                    imagePath = "/images/noimage.png"

                  if result.vid
                    videoPath = "/files/#{result.vid}"
 
                  unless result.nickname
                    result.nickname = "不明"

                  @videos.push
                    _id: result._id
                    nickname: result.nickname
                    imagePath: imagePath
                    vid: result.vid
                    videoPath: videoPath
                    selected: false
                return
              .catch (err) ->
                console.log err
                return
          else
            height = $(window).height()
            top = Math.random() * (height + 1 - 50)
            data.top = top
            @comments.push data

            setTimeout () =>
              @comments.shift()
              return
            , 6000
          return
        return
  return
