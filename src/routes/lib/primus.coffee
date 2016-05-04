Primus = require "primus"
Emitter = require "primus-emitter"
Rooms = require "primus-rooms"

primus = undefined
room = undefined

exports.init = (server) ->
  primus = new Primus server,
    pathname: "/primus"
    parser: "JSON"
    transformer: "sockjs"

  primus.use "emitter", Emitter
  primus.use "rooms", Rooms

  # Connect
  primus.on "connection", (spark) ->
    console.log "connect"
    spark.on "join", (data) ->
      sid = data.sid
      room = sid
      spark.join room
      return

    return

  primus.on "disconnection", (spark) ->
    console.log "disconnect"
    return

# Websocketメッセージ
exports.sendVideo = (data) ->
  if data.ok
    ms =
      _id: data._id

    primus
      .in room
      .send "video", ms
  return

exports.sendComment = (data) ->
  if data.ok
    ms =
      nickname: data.nickname
      text: data.text
      stamp: data.stamp
      sntdt: data.sntdt

  primus
    .in room
    .send "comment", ms
  return
