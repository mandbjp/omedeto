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
      stamps: ["stamp001.png","stamp002.png"]
      comments: []
      lastLoadedId: ""
      preLastLoadedId: ""
      pos: 0
      prePos: 0
      posCount: 1
      query:
        skip: 0
        limit: 20
      stampView: false
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
            @preLastLoadedId = @lastLoadedId
            for val in results
              if val.sntdt
                val.sntdt = moment(new Date(val.sntdt)).format "MM/DD HH:mm"
              @comments.unshift val
              @lastLoadedId = val._id
            resolve()
            if @preLastLoadedId is ""
              @preLastLoadedId = val._id
            #console.log @preLastLoadedId
            #console.log @lastLoadedId
            return
          .catch (err) ->
            console.log err
            resolve()
            return
          return
      # Reload
      reloadList: () ->
        @comments = []
        @lastLoadedId = ""
        @preLastLoadedId = ""
        @loadMore()
        .then () ->
          setTimeout () ->
            $("#history").scrollTop $(".commentList").height()
            return
          , 10
          return
        $("#history").scroll (e) =>
          target = e.target
          #clientHeight = target.clientHeight
          #scrollHeight = target.scrollHeight
          #maxScroll = scrollHeight - clientHeight
          scrollTop = target.scrollTop
          #console.log clientHeight
          #console.log scrollHeight
          #console.log maxScroll
          #console.log scrollTop
          
          #console.log "top:#{scrollTop}"
          #console.log $(".item")

          if scrollTop is 0
            @loadMore()
            topPos = $(".commentList").scrollTop()
            currentPos = $("#" + @preLastLoadedId).scrollTop()
            pos = @comments.length * $(".item").height
            
            #各種パラメータ確認
            console.log "#{topPos}"
            console.log "#{currentPos}"
            console.log @comments.length
            console.log $(".item").height
            console.log "#{pos}"



            # console.log @posCount
            # console.log $(".commentList").height()
            # @pos = $("#" + @preLastLoadedId).offset().top
            # if @pos is @prePos
            #   @posCount += 1
            # if @posCount isnt 1
            #   @pos *= @posCount
            #   @posCount += 0.8
            # console.log @prePos
            # console.log @pos
            # @prePos = @pos
            # #console.log $("#" + @preLastLoadedId)
            # calPos = $(".commentList").height() - @pos
            # console.log calPos
            # $("#history").animate({ scrollTop: calPos }, 'fast')
            
            
            
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
            if data.sntdt
              data.sntdt = moment(new Date(data.sntdt)).format "MM/DD HH:mm"
            @comments.push data
            setTimeout () ->
              $("#history").scrollTop $(".commentList").height()
              return
            , 10
          return
        return
  return
