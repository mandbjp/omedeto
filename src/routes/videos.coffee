Promise = require("q").promise
mongo = require "./lib/mongo"
ObjectID = mongo.ObjectID
primus = require "./lib/primus"

getData = (query) ->
  return Promise (resolve, reject) ->
    _id = query._id
    vid = query.vid
    type = query.type
    skip = query.skip
    limit = query.limit

    crt =
      sid: "omedeto"

    if _id
      crt._id = new ObjectID _id

    if vid
      crt.vid = vid

    opt =
      sort:
        sntdt: 1

    if skip
      opt.skip = +skip
    else
      opt.skip = 0

    if limit
      opt.limit = +limit
    else
      opt.limit = 10

    flag = if type is "count" then false else true

    mongo.find "omedeto", "video", crt, {}, opt
    .then (cursor) ->
      if flag
        cursor.toArray()
        .then resolve, reject
      else
        result = cursor.count false
        .then (cnt) ->
          result =
            count: cnt
          resolve result
          return
        .catch (err) ->
          reject err
          return
      return
    .catch (err) ->
      reject err
      return
    return

setData = (data) ->
  return Promise (resolve, reject) ->
    sid = data.sid
    vid = data.vid
    tid = data.tid
    nickname = data.message

    doc =
      sid: sid
      vid: vid

    if tid
      doc.tid = tid

    if nickname
      doc.nickname = nickname

    doc.sntdt = new Date()

    opt = {}

    mongo.insert "omedeto", "video", doc, opt
    .then (result) ->
      if result
        result._id = doc._id
      resolve result
      return
    .catch (err) ->
      reject err
      return
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
    status = if result.ok then 200 else 400
    if status is 200
      query =
        ok: result.ok
        type: "video"
        _id: result._id

      primus.send query

    res.status status
      .send result
    return
  .catch (err) ->
    res.status err.code
      .send err.msg
    return

  return
