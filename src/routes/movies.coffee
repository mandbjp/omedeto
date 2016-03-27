Promise = require("q").promise

getData = (data) ->
  return Promise (resolve, reject) ->
    output = []
    for val in [1..10]
      output.push
        id: val
        message: "おめでとうございます。#{val}"
        file: "hogehoge#{val}.mp4"

    resolve output
    return

setData = (data) ->
  return Promise (resolve, reject) ->
    resolve()
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

# 動画追加 (POST)
exports.create = (req, res) ->
  query = req.body

  # Validation 追加予定

  setData param
  .then (result) ->
    status = if result.outCode >= 0 then 200 else 400
    res.status status
      .send result
    return
  .catch (err) ->
    res.status err.code
      .send err.msg
    return

  return
