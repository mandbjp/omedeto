browserify = require "browserify"
coffee = require "gulp-coffee"
concat = require "gulp-concat"
del = require "del"
gulp = require "gulp"
foreach = require "gulp-foreach"
fs = require "fs"
minifycss = require "gulp-minify-css"
nodemon = require "nodemon"
path = require "path"
runSequence = require "run-sequence"
stylus = require "gulp-stylus"
source = require "vinyl-source-stream"

# app
gulp.task "app", () ->
  return gulp.src "./src/*.coffee"
    .pipe coffee()
    .pipe gulp.dest "./"

# route
gulp.task "routes", ["lib"], () ->
  return gulp.src "./src/routes/*"
    .pipe coffee()
    .pipe gulp.dest "./routes/"

# route/lib
gulp.task "lib", () ->
  return gulp.src "./src/routes/lib/*"
    .pipe coffee()
    .pipe gulp.dest "./routes/lib/"

# coffee
gulp.task "coffee", () ->
  return gulp.src "./src/coffee/*.coffee"
    .pipe foreach (stream, file) ->
      filename = path.basename file.path, ".coffee"
      return browserify
        transform: ['coffeeify']
        entries: file.path
        extensions: [".coffee"]
        debug: true
      .bundle()
      .pipe source "#{filename}.js"
    .pipe gulp.dest "./dist/js"

# stylus
gulp.task "stylus", () ->
  return gulp.src "./src/stylus/*.styl"
    .pipe foreach (stream, file) ->
      return stream.pipe stylus()
    .pipe minifycss
      keepBreaks: true
    .pipe gulp.dest "./dist/css"

# js
gulp.task "vendor-js", () ->
  return gulp.src [
    "./bower_components/jquery/dist/jquery.min.js"
    "./bower_components/bootstrap/dist/js/bootstrap.min.js"
  ]
  .pipe concat "vendor.js"
  .pipe gulp.dest "./dist/js"

# css
gulp.task "vendor-css", () ->
  return gulp.src [
    "./bower_components/bootstrap/dist/css/bootstrap.min.css"
  ]
  .pipe concat "vendor.css"
  .pipe minifycss
    keepBreaks: true
  .pipe gulp.dest "./dist/css"

# fonts
gulp.task "fonts", () ->
  return gulp.src [
    "./bower_components/bootstrap/dist/fonts/*"
  ]
  .pipe gulp.dest "./dist/fonts"

# images
gulp.task "images", () ->
  return gulp.src "./src/images/*"
    .pipe gulp.dest "./dist/images/"

gulp.task "watch", () ->
  gulp.watch "./src/*.coffee", ["app"]
  gulp.watch [
    "./src/routes/*.coffee"
    "./src/routes/lib/*.coffee"
  ], ["routes"]
  gulp.watch [
    "./src/coffee/*.coffee"
    "./src/coffee/lib/*.coffee"
  ], ["coffee"]
  gulp.watch [
    "./src/stylus/*.styl"
    "./src/stylus/lib/*.styl"
  ], ["stylus"]
  gulp.watch [
    "./src/images/*"
  ], ["images"]
  return

gulp.task "nodemon", () ->
  nodemon
    script: "./app.js"
    env:
      NODE_ENV: "development"

gulp.task "del", () ->
  return del.sync [
    "./dist"
    "./routes"
    "./*.js"
  ]

gulp.task "build", (done) ->
  return runSequence "del",
    [
      "app"
      "routes"
      "coffee"
      "stylus"
      "vendor-js"
      "vendor-css"
      "fonts"
      "images"
    ]

# preview
gulp.task "default", ["watch"], (done) ->
  return runSequence "del",
    [
      "app"
      "routes"
      "coffee"
      "stylus"
      "vendor-js"
      "vendor-css"
      "fonts"
      "images"
    ],
    "nodemon"
