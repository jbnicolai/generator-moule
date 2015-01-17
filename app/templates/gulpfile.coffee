browserSync = require "browser-sync"
cache = require "gulp-cached"
coffee = require "gulp-coffee"
del = require "del"
gulp = require "gulp"
gutil = require "gulp-util"
mediaQueries = require "gulp-combine-media-queries"
minifyCSS = require "gulp-minify-css"
minifyJS = require "gulp-uglify"
prefix = require "gulp-autoprefixer"
runSequence = require "run-sequence"
sass = require "gulp-sass"
scssLint = require "gulp-scss-lint"
shell = require "gulp-shell"

messages =
  jekyllBuild: "Rebuilding Jekyll..."

sourceFolder = "./source"
destinationFolder = "./_site"

paths =
  sass: "#{sourceFolder}/_scss/"
  coffee: "#{sourceFolder}/_coffee/"
  styles: "#{sourceFolder}/css/"
  destinationStyles: "#{destinationFolder}/css/"
  scripts: "#{sourceFolder}/scripts/"
  destinationScripts: "#{destinationFolder}/scripts/"
  jekyllFiles: ["#{sourceFolder}/**/*.md", "#{sourceFolder}/**/*.html", "#{sourceFolder}/**/*.xml", "./**/*.yml"]

gulp.task "default", ["develop"]

gulp.task "develop", ->
  runSequence ["watch", "browser-sync"]

gulp.task "build", ->
  runSequence ["sass", "coffee"], "lintSass", ["minifyCSS", "minifyJS"], "jekyll-build"

gulp.task "clean",
  del.bind(null, ["_site"])

gulp.task "watch", ["sass", "coffee", "jekyll-serve"], ->
  gulp.watch "#{paths.sass}/*.scss", ["sass"]
  gulp.watch "#{paths.coffee}/*.coffee", ["coffee"]
  gulp.watch paths.jekyllFiles, ["jekyll-rebuild"]

gulp.task "jekyll-serve",
  shell.task "jekyll build --config _config.yml,_config.serve.yml", quiet: true
  browserSync.notify messages.jekyllBuild

gulp.task "jekyll-build",
  shell.task "jekyll build"

gulp.task "jekyll-rebuild", ["jekyll-serve"], ->
  browserSync.reload()

gulp.task "doctor",
  shell.task "jekyll doctor"

gulp.task "sass", ->
  gulp.src("#{paths.sass}/*.scss")
    .pipe sass
      errLogToConsole: true
      precision: 2
    .pipe prefix ["last 2 versions", "> 2%", "ie 11", "Firefox ESR"], cascade: false
    .pipe mediaQueries()
    .pipe gulp.dest(paths.destinationStyles)
    .pipe gulp.dest(paths.styles)
    .pipe browserSync.reload(stream: true)

gulp.task "minifyCSS", ->
  gulp.src("#{paths.destinationStyles}/*.css")
    .pipe cache paths.styles
    .pipe minifyCSS()
    .pipe gulp.dest(paths.destinationStyles)
    .pipe gulp.dest(paths.styles)

gulp.task "lintSass", ->
  gulp.src("#{paths.sass}/*.scss")
    .pipe cache paths.sass
    .pipe scssLint
      "config": ".scss-lint.yml",
      "bundleExec": true
    .pipe scssLint.failReporter()
    .on "error", (error) -> gutil.log(error.message)

gulp.task "coffee", ->
  gulp.src("#{paths.coffee}/*.coffee")
    .pipe cache paths.coffee
    .pipe coffee bare: true
    .on "error", (error) -> gutil.log(error.message)
    .pipe gulp.dest(paths.destinationScripts)
    .pipe gulp.dest(paths.scripts)
    .pipe browserSync.reload(stream: true)

gulp.task "minifyJS", ->
  gulp.src("#{paths.destinationScripts}/*.js")
    .pipe cache paths.scripts
    .pipe minifyJS()
    .pipe gulp.dest(paths.destinationScripts)
    .pipe gulp.dest(paths.scripts)

gulp.task "browser-sync", ->
  browserSync.init null,
    server:
      baseDir: "_site"
    host: "localhost"
    port: 4000
    open: true
    browser: "chrome"
