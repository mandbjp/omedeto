config = require("../config").config

exports.index = (req, res) ->
  accept = req.headers.accept
  auth = req.user
  if auth is config.auth.admin.user
    admin = true
  else
    admin = false
  if accept.match "html"
    res.render "list",
      pretty: true
      title: "omedeto"
      admin: admin
  return
