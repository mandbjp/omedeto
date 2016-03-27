express = require "express"
http = require "http"
favicon = require "serve-favicon"
fs = require "fs"
stylus = require "stylus"
compression = require "compression"
bodyParser = require "body-parser"
moment = require "moment"
#csrf = require "csurf"
helmet = require "helmet"

app = express()
server = http.createServer app
app.use helmet()

# 開発環境用Config
if app.get("env") is "development"
  config = require("./config").development
# 本番環境要Config
if app.get("env") is "production"
  config = require("./config").production

app.set "port", config.port
app.set "views", "./src/views"
app.set "view engine", "jade"
app.set "x-powered-by", "false"
app.use compression
  level: 1
app.use bodyParser.json()
app.use bodyParser.urlencoded
  extended: true

# csrf対策
#app.use csrf()
#app.use (err, req, res, next) ->
#  if err.code isnt "EBADCSRFTOKEN"
#    return next err
#  res.status 403
#    .send "session has expired or form tampered with"
#  return

# lang, csrfToken設定
app.use (req, res, next) ->
  res.locals.lang = if req.locale then req.locale.substr(0,2) else "en"
  #res.locals.csrfToken = req.csrfToken()
  next()
  return

files = []
for val in fs.readdirSync "./routes"
  if val.match ".js"
    files.push val.replace /\.js$/, ""

for val in files
  api = require("./routes/#{val}")
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
