# upload画面表示
exports.index = (req, res) ->
  accept = req.headers.accept
  if accept.match "html"
    res.render "local_video",
      pretty: true
  return
