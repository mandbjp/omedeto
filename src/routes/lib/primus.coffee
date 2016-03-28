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

exports.send = (data) ->
  ms =
    _id: data[0]._id
  primus
    .in room
    .write ms
  return
