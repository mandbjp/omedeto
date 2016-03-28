express = require "express"
http = require "http"
favicon = require "serve-favicon"
fs = require "fs"
stylus = require "stylus"
compression = require "compression"
bodyParser = require "body-parser"
moment = require "moment"
multipart = require "connect-multiparty"
helmet = require "helmet"
primus = require "./routes/lib/primus"

app = express()
server = http.createServer app
app.use helmet()

config = require("./config").config

app.set "port", config.port
app.set "views", "./src/views"
app.set "view engine", "jade"
app.set "x-powered-by", "false"
app.use compression
  level: 1
app.use bodyParser.json()
app.use bodyParser.urlencoded
  extended: true

# lang設定
app.use (req, res, next) ->
  res.locals.lang = if req.locale then req.locale.substr(0,2) else "en"
  next()
  return

primus.init server

app.use multipart
  uploadDir: __dirname + "/upload"
  limit: "1000mb"

# ファイルのUpload / Download
image = require "./routes/image"
app.post "/upload/image", image.upload
app.get "/images/:fileName/:size", image.download

# Web-APIの各ターゲットに処理をマップする
files = []
for val in fs.readdirSync "./routes"
  if val.match ".js"
    files.push val.replace /\.js$/, ""

for val in files
  api = require "./routes/#{val}"
  if val is "index" then val = ""
  if api.index then app.get "/#{val}", api.index
  if api.create then app.post "/#{val}", api.create
  if api.show then app.get "/#{val}/:id", api.show
  if api.update then app.put "/#{val}/:id", api.update
  if api.destroy then app.delete "/#{val}/:id", api.destroy

app.use express.static "./dist"

server.listen app.get("port"), ->
  console.log "Server listen
    on port #{app.get('port')}
    at #{moment().format('YYYY/MM/DD HH:mm:SS')}"
  return
