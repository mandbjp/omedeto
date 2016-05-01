config = require("../config").config

exports.index = (req, res) ->
  accept = req.headers.accept
  # auth = req.user
  # if auth is config.auth.admin.user
  #   admin = true
  # else
  #   admin = false
  if accept.match "html"
    query = req.query
    user = query.user
    pass = query.pass
    admin = config.auth.admin

    if user is admin.user and pass is admin.password
      admin = true
    else
      admin = false

    res.render "list",
      pretty: true
      title: "omedeto"
      admin: admin
  return
