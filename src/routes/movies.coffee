Promise = require("q").promise
mongo = require "./lib/mongo"
ObjectID = mongo.ObjectID
primus = require "./lib/primus"

getData = (query) ->
  return Promise (resolve, reject) ->
    _id = query._id
    crt =
      sid: "omedeto"

    if _id
      crt._id = new ObjectID _id

    opt =
      sort:
        sntdt: 1

    mongo.find "omedeto", "movie", crt, {}, opt, true, (err, result) ->
      if err
        reject result
      else
        resolve result
      return

    return

setData = (data) ->
  return Promise (resolve, reject) ->
    sid = data.sid
    thumbnail = data.thumbnail
    message = data.message

    doc =
      sid: sid
    if thumbnail
      doc.thumbnail = thumbnail

    if message
      doc.message = message

    doc.sntdt = new Date()

    opt = {}

    mongo.insert "omedeto", "movie", doc, opt, (err, result) ->
      if err
        console.log err
        reject result
      else
        resolve result
    return


# 動画一覧取得 (GET)
exports.index = (req, res) ->
  query = req.query

  # Validation 追加予定

  getData query
  .then (result) ->
    res.status 200
      .send result
    return
  .catch (err) ->
    res.status err.code
      .send err.msg
    return
  return

# 動画情報取得 (GET)
exports.show = (req, res) ->
  query = req.query
  query._id = req.params.id

  # Validation 追加予定

  getData query
  .then (result) ->
    res.status 200
      .send result[0]
    return
  .catch (err) ->
    res.status err.code
      .send err.msg
    return
  return


# 動画追加 (POST)
exports.create = (req, res) ->
  param = req.body
  param.sid = "omedeto"

  # Validation 追加予定

  setData param
  .then (result) ->
    status = if result.insertedCount > 0 then 200 else 400
    if status is 200
      primus.send result.ops
    res.status status
      .send result.ops
    return
  .catch (err) ->
    res.status err.code
      .send err.msg
    return

  return
