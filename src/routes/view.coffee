exports.index = (req, res) ->
  accept = req.headers.accept
  if accept.match "html"
    res.render "view",
      pretty: true
  return
