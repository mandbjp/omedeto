$ ->
  Vue =  require "vue"
  Vue.use require "vue-resource"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  files = new Ajax "files"
  videos = new Ajax "videos"
  require "./lib/header"

  # index画面のVueModel
  vm = new Vue
    el: "#content"
    template: "#template"
    replace: false
    data:
      videos: []
      video: ""
      query:
        sid: ""
        search: ""
        skip: 0
        limit: ""
      count: 0
      sortMode: false
    created: () ->
      @query.sid = "omedeto"
      @reloadList()
      return
    methods:
      # 動画を取得し一覧に表示
      loadMore: () ->
        @getVideos @query
        .then (results) =>
          @query.skip += results.length
          for val in results
            if val.tid
              val.imagePath = "/files/#{val.tid}/300x300"
            else
              val.imagePath = "/images/noimage.png"
            unless val.nickname
              val.nickname = "ニックネーム未登録"
            val.checked = false
            val.loading = false
            @videos.push val
          return
        .catch (err) ->
          console.log err
          return
        return

      # 一覧をリロード
      reloadList: () ->
        @videos = []
        @sortMode = false
        @query.skip = 0
        @query.limit = ""
        @query.type = "count"
        # 件数取得
        @getVideos @query
        .then (result) =>
          if result
            @count = result.count
          @query.limit += 12
          @query.type = "list"
          @loadMore()
          return
        .catch (err) ->
          console.log err
          return
        return

      # 動画一覧取得
      getVideos: (query) ->
        return Promise (resolve, reject) ->
          videos
          .index query
          .then (results) ->
            resolve results
            return
          .catch (err) ->
            console.log err
            reject err
            return
          return

      # 動画情報取得
      getVideo: (id) ->
        return Promise (resolve, reject) ->
          videos
          .show id
          .then (results) ->
            resolve results
            return
          .catch (err) ->
            console.log err
            reject err
            return
          return

      # Viewをカウント
      countView: (data) ->
        id = data._id

        unless data.view
          data.view = 0
        data.view++
        query =
          view: data.view

        videos.update id, query

        return

      # Video loading
      loading: (id) ->
        for val in @videos
          if id is val._id
            val.loading = true
        return

      # Video loaded
      loaded: (id) ->
        for val in @videos
          if id is val._id
            val.loading = false
        return
 
      # サムネイルをクリック
      showVideo: (id) ->
        for val in @videos
          if val.loading
            alert "別の動画を現在読込中です。表示されるまでお待ち下さい。"
            return
        @loading id
        @getVideo id
        .then (result) =>
          if result.vid
            vid = if result.vid_low then result.vid_low else result.vid
            query =
              type: "video"
            files
            .show vid, query
            .then (videoData) =>
              # base64で表示
              result.videoPath = "data:video/mp4;base64,#{videoData}"

              if result.tid
                result.imagePath = "/files/#{result.tid}/300x300"
              else
                result.imagePath = "/images/noimage.png"

              @video = result
              @countView result
              @loaded id
              return
            .catch (err) ->
              console.log err
              @loaded id
              return
          return
        .catch (err) ->
          console.log err
          @loaded id
          return
        return

      # 動画を閉じる
      closeVideo: () ->
        @video = ""
        $(".detail video").get(0).pause()
        return

      # 一覧選択
      selectItem: (id) ->
        if @sortMode
          for val in @videos
            if val._id is id
              if val.checked
                val.checked = false
              else
                val.checked = true
        else
          @showVideo id
        return

      # 選択動画を一つ前に移動
      movePrev: () ->
        for val, index in @videos
          if val.checked
            if index > 0
              @videos.splice index - 1 , 2, @videos[index], @videos[index - 1]
            else
              return
        return

      # 選択動画を一つ後ろに移動
      moveNext: () ->
        for index in [@videos.length - 1 .. 0]
          if @videos[index].checked
            if index < @videos.length - 1
              @videos.splice index, 2, @videos[index + 1], @videos[index]
            else
              return
        return

      # 取消ボタンクリック
      sortCancel: () ->
        @sortMode = false
        @reloadList()
        return

      # 保存ボタンクリック
      sortSave: () ->
        success = 0
        @videos.reduce (promise, data, index) =>
          return promise.then () =>
            id = data._id
            param =
              order: index + 1
            videos
            .update id, param
            .then (result) =>
              if result.n
                success++
              return
            .catch (err) ->
              console.log err
              return
            return
        , Promise.resolve()
          .then () =>
            alert "動画の表示順を変更しました。"
            @reloadList()
          .catch (err) ->
            console.log err
            return
        return
  return
