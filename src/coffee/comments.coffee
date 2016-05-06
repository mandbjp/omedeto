$ ->
  Vue =  require "vue"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  comments = new Ajax "comments"
  db = require "localforage"
  require "./lib/header"
  moment = require "moment"
  primus = new Primus("/primus")

  # 検証用コメント画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      nickname: ""
      text: ""
      stamps: [
        "stamp001.gif","stamp002.gif","stamp003.gif","stamp004.gif","stamp005.png",
        "stamp006.png","stamp007.png","stamp008.png","stamp009.png","stamp010.png",
        "stamp011.png","stamp012.png","stamp013.png","stamp014.png","stamp015.png",
        "stamp016.png","stamp017.png","stamp018.png",
        "stamp101.gif","stamp102.gif","stamp103.gif","stamp104.gif","stamp105.gif"
      ]
      comments: []
      query:
        skip: 0
        limit: 20
      stampView: false
      scrollMode: false
    created: () ->
      db.getItem "nickname"
      .then (val) =>
        @nickname = val
        @reloadList()
        room =
          sid: "omedeto"
        @connectWS room
        return
      .catch (err) ->
        console.log err
        return
      return
    methods:
      loadMore: () ->
        return Promise (resolve, reject) =>
          @getComments @query
          .then (results) =>
            @query.skip += results.length
            for val in results
              unless val.nickname
                val.nickname = "ゲスト"
              if val.sntdt
                val.sntdt = moment(new Date(val.sntdt)).format "MM/DD HH:mm"
              @comments.unshift val
            resolve results
            return
          .catch (err) ->
            console.log err
            resolve []
            return
          return

      # Reload
      reloadList: () ->
        @comments = []
        @loadMore()
        .then () ->
          setTimeout () ->
            $("#history").scrollTop $(".commentList").height()
            return
          , 10
          return
        # スクロールイベント
        $("#history").scroll (e) =>
          target = e.target
          scrollTop = target.scrollTop
          #@scrollMode = true
          # 一番上までスクロールした場合
          if scrollTop is 0
            # データ取得
            @loadMore()
            .then (data) ->
              if data.length
                setTimeout () ->
                  scrollPosition = 0
                  # 追加されたitemのheightを取得
                  for val, index in data
                    scrollPosition += $($(".commentList .item")[index]).height() + 6
                  # スクロール移動
                  $("#history").scrollTop scrollPosition
                  return
                , 10
              return
          #else if scrollTop is $(".commentList").height()
          #  console.log "bottom"
          #  @scrollMode = false
          return
        return

      # Comment一覧取得
      getComments: (query) ->
        return Promise (resolve, reject) ->
          comments
          .index query
          .then (results) ->
            resolve results
            return
          .catch (err) ->
            console.log err
            reject err
            return
          return

      toggleStamp: () ->
        @stampView = if @stampView then false else true
        return

      # テキストを送信
      sendText: () ->
        if @text
          param =
            nickname: @nickname
            text: @text
          @send param
        return

      # スタンプを送信
      sendStamp: (stamp) ->
        param =
          nickname: @nickname
          stamp: stamp
        @send param
        @stampView = false
        return

      # Comment送信
      send: (param) ->
        comments
        .create param
        .then (result) =>
          @text = ""
          return
        .catch (err) ->
          console.log err
          return
        return

      # WebSocket接続
      connectWS: (room) ->
        # Join
        primus.send "join", room
        # Commentを受け取る
        primus.on "comment", (data) =>
          if data
            unless data.nickname
              data.nickname = "ゲスト"
            if data.sntdt
              data.sntdt = moment(new Date(data.sntdt)).format "MM/DD HH:mm"
            @comments.push data
            setTimeout () =>
              #console.log @scrollMode
              unless @scrollMode
                $("#history").scrollTop $(".commentList").height()
              return
            , 10
          return
        # 再接続
        primus.on "reconnected", () ->
          primus.send "join", room
          return
        return
  return
