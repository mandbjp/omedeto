Primus = require "primus"
Rooms = require "primus-rooms"

primus = undefined
room = undefined

exports.init = (server) ->
  primus = new Primus server,
    pathname: "/primus"
    parser: "JSON"
    transformer: "sockjs"

  primus.use "rooms", Rooms

  # Connect
  primus.on "connection", (spark) ->
    spark.on "data", (data) ->
      sid = data.sid
      room = sid
      spark.join room
      return

    return

# Websocketメッセージ
exports.send = (data) ->
  if data.ok
    type = data.type
    if type is "video"
      ms =
        type: type
        _id: data._id

    else if type is "comment"
      ms =
        type: type
        nickname: data.nickname
        content: data.content
        ekey: data.ekey

    primus
      .in room
      .write ms
  return
