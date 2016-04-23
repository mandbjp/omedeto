Promise = require("q").promise
mongo = require "./lib/mongo"
ObjectID = mongo.ObjectID
primus = require "./lib/primus"
config = require("./../config").config

getData = (query) ->
  return Promise (resolve, reject) ->
    _id = query._id
    type = query.type
    skip = query.skip
    limit = query.limit

    crt =
      sid: "omedeto"

    if _id
      crt._id = new ObjectID _id

    opt =
      sort:
        sntdt: -1

    if skip
      opt.skip = +skip
    else
      opt.skip = 0

    if limit
      opt.limit = +limit
    else
      opt.limit = 10

    flag = if type is "count" then false else true

    mongo.find config.mongo.db, config.mongo.collection.comment, crt, {}, opt
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
    nickname = data.nickname
    text = data.text
    stamp = data.stamp
    sntdt = data.sntdt

    doc =
      sid: sid

    if nickname
      doc.nickname = nickname

    if text
      doc.text = text

    if stamp
      doc.stamp = stamp

    doc.sntdt = sntdt

    opt = {}

    mongo.insert config.mongo.db, config.mongo.collection.comment, doc, opt
    .then (result) ->
      resolve result
      return
    .catch (err) ->
      reject err
      return
    return


# コメント一覧取得 (GET)
exports.index = (req, res) ->
  query = req.query
  accept = req.headers.accept

  if accept.match "html"
    res.render "comments",
      pretty: true

  else
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

# コメント情報取得 (GET)
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


# コメント追加 (POST)
exports.create = (req, res) ->
  param = req.body
  param.sid = "omedeto"
  param.sntdt = new Date()

  # Validation 追加予定
  setData param
  .then (result) ->
    status = if result.ok then 200 else 400
    if status is 200
      query =
        ok: result.ok
        nickname: param.nickname
        text: param.text
        stamp: param.stamp
        sntdt: param.sntdt

      primus.sendComment query

    res.status status
      .send result
    return
  .catch (err) ->
    res.status err.code
      .send err.msg
    return

  return
