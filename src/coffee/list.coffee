$ ->
  Vue =  require "vue"
  Ajax = require "./lib/ajax"
  Q = require "q"
  Promise = Q.Promise
  files = new Ajax "files"
  videos = new Ajax "videos"

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
      count: ""
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
              val.imagePath = "/files/#{val.tid}"
            else
              val.imagePath = "/images/noimage.png"
            unless val.nickname
              val.nickname = "不明"
            @videos.push val
          return
        .catch (err) ->
          console.log err
          return
        return

      # 一覧をリロード
      reloadList: () ->
        @videos = []
        @query.skip = 0
        @query.limit = ""
        @query.type = "count"
        # 件数取得
        @getVideos @query
        .then (result) =>
          if result
            @count = result.count
          @query.limit += 10
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

      # サムネイルをクリック
      showVideo: (id) ->
        @getVideo id
        .then (result) =>
          if result.vid
            result.videoPath = "/files/#{result.vid}"

          if result.tid
            result.imagePath = "/files/#{result.tid}"
          else
            result.imagePath = "/images/noimage.png"

          @video = result
          return
        .catch (err) ->
          console.log err
          return
        return

      # 動画を閉じる
      closeVideo: () ->
        @video = ""
        $(".detail video").get(0).pause()
        return
  return
