Promise = require("q").promise
mongo = require "./lib/mongo"
ObjectID = mongo.ObjectID
primus = require "./lib/primus"
config = require("./../config").config

getData = (query) ->
  return Promise (resolve, reject) ->
    _id = query._id
    vid = query.vid
    type = query.type
    skip = query.skip
    limit = query.limit
    search = query.search

    crt =
      sid: "omedeto"
      disable:
        $exists: false

    if _id
      crt._id = new ObjectID _id

    if vid
      crt.vid = vid

    if search
      crt.nickname = ///#{search}///

    opt =
      sort:
        order: 1

    if skip
      opt.skip = +skip
    else
      opt.skip = 0

    if limit
      opt.limit = +limit
    else
      opt.limit = 12

    flag = if type is "count" then false else true

    mongo.find config.mongo.db, config.mongo.collection.video, crt, {}, opt
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

insertData = (data) ->
  return Promise (resolve, reject) ->
    sid = data.sid
    vid = data.vid
    tid = data.tid
    vid_low = data.vid_low
    nickname = data.nickname
    order = data.order

    doc =
      sid: sid
      vid: vid

    if tid
      doc.tid = tid

    if vid_low
      doc.vid_low = vid_low

    if nickname
      doc.nickname = nickname

    if order
      doc.order = order
    else
      doc.order = 9999
    doc.view = 0
    doc.sntdt = new Date()
    doc.uptdt = new Date()

    opt = {}

    mongo.insert config.mongo.db, config.mongo.collection.video, doc, opt
    .then (result) ->
      if result
        result._id = doc._id
      resolve result
      return
    .catch (err) ->
      reject err
      return
    return

updateData = (data) ->
  return Promise (resolve, reject) ->
    _id = data._id
    sid = data.sid
    vid = data.vid
    tid = data.tid
    vid_low = data.vid_low
    nickname = data.nickname
    order = data.order
    view = data.view

    crt =
      sid: sid
      _id: new ObjectID _id

    doc =
      $set: {}

    if vid
      doc.$set.vid = vid

    if tid
      doc.$set.tid = tid

    if vid_low
      doc.$set.vid_low = vid_low

    if nickname
      doc.$set.nickname = nickname

    if order
      doc.$set.order = order

    if view
      doc.$set.view = view

    doc.$set.uptdt = new Date()
    opt = {}
    mongo.update config.mongo.db, config.mongo.collection.video, crt, doc, opt
    .then (result) ->
      if result
        result._id = doc._id
      resolve result
      return
    .catch (err) ->
      reject err
      return
    return

removeData = (data) ->
  return Promise (resolve, reject) ->
    _id = data._id
    sid = data.sid
    disable = data.disable

    crt =
      sid: sid
      _id: new ObjectID _id

    doc =
      $set: {}

    if disable
      doc.$set.disable = true

    doc.$set.uptdt = new Date()

    opt = {}
    mongo.update config.mongo.db, config.mongo.collection.video, crt, doc, opt
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
  insertData param
  .then (result) ->
    status = if result.ok then 200 else 400
    if status is 200
      query =
        ok: result.ok
        _id: result._id

      primus.sendVideo query

    res.status status
      .send result
    return
  .catch (err) ->
    res.status err.code
      .send err.msg
    return

  return


# 動画編集 (PUT)
exports.update = (req, res) ->
  param = req.body
  param._id = req.params.id
  param.sid = "omedeto"

  # Validation 追加予定
  updateData param
  .then (result) ->
    status = if result.ok then 200 else 400
    res.status status
      .send result
    return
  .catch (err) ->
    res.status err.code
      .send err.msg
    return

  return

# 動画削除 (DELETE)
exports.destroy = (req, res) ->
  param = req.body
  param._id = req.params.id
  param.sid = "omedeto"

  removeData param
  .then (result) ->
    status = if result.ok >= 0 then 200 else 400
    res.status status
      .send result
    return
  .catch (err) ->
    res.status err.code
      .send err.msg
    return
  return
