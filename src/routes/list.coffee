exports.index = (req, res) ->
  accept = req.headers.accept
  if accept.match "html"
    res.render "list",
      pretty: true
      title: "omedeto"
  return
