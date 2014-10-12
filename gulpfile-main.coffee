dev = false
# ORDER OF TASKS
runSequence = require 'run-sequence'
# components
mainBowerFiles = require 'main-bower-files'
# GULP
gulp = require 'gulp'
gutil = require 'gulp-util'
clean = require 'gulp-clean'
concat = require 'gulp-concat'
rename = require 'gulp-rename'
# SERVER
connect = require 'gulp-connect'
open = require 'gulp-open'
# CSS
scss = require 'gulp-sass'
bourbon = require 'node-bourbon'
# JAVASCRIPT
coffee = require 'gulp-coffee'
sourcemaps = require 'gulp-sourcemaps'
# HTML
jade = require 'gulp-jade'
inject = require 'gulp-inject'
injectString = require 'gulp-inject-string'

paths =
  fonts: ['./app/fonts/**/*.*']
  scss: ['./app/styles/**/*.scss','./app/styles/**/*.sass']
  coffee: ['./app/scripts/**/*.coffee']
  views: ['./app/views/*.jade']
  views_all: ['./app/views/**/*.jade']
  images: ['./app/images/**/*.*']
  inject_js: [
    './www/components/jquery.js',
    './www/components/**/*.js',
    './www/scripts/**/*.js'
  ]
  inject_css: [
    './www/components/**/*.css'
    './www/styles/**/*.css'
  ]

options = ->
  scss:
    errLogToConsole: true
    imagePath: '../images'
    includePaths: bourbon.includePaths
    outputStyle: if dev then 'expanded' else 'compressed'
  server:
    port: 9001,
    host: 'localhost'
    root: 'www'
    livereload: true

on_error = (error) ->
  gutil.beep()
  gutil.log error


# TASKS
gulp.task 'clean', ->
  gulp.src './www', {read: false}
  .pipe clean force: true

gulp.task 'bower', ->
  gulp.src mainBowerFiles()
    .pipe gulp.dest './www/components'
    .on 'error', on_error

gulp.task 'dev', ->
  dev = true

gulp.task 'scss', (done) ->
  gulp.src paths.scss
    .pipe scss(options().scss)
    .pipe gulp.dest './www/styles/'
    .pipe connect.reload()
    .on 'end', done
  return

gulp.task 'coffee', ->
  gulp.src paths.coffee
    .pipe sourcemaps.init()
    .pipe coffee {bare: true}
    .on 'error', on_error
    .pipe sourcemaps.write '../maps'
    .pipe gulp.dest './www/scripts'
    .pipe connect.reload()

gulp.task 'jade', ->
  gulp.src paths.views
    .pipe jade pretty: true
    .pipe injectString.after('<!--inject-css-->', '    <!-- inject:css -->\n    <!-- endinject -->\n')
    .pipe injectString.after('<!--inject-js-->', '    <!-- inject:js -->\n    <!-- endinject -->\n')
    .pipe inject gulp.src(paths.inject_css, {read: false}), { ignorePath: 'www', relative: false }
    .pipe inject gulp.src(paths.inject_js), { ignorePath: 'www', relative: false }
    .pipe gulp.dest './www'
    .pipe connect.reload()

gulp.task 'images', ->
  gulp.src paths.images
    .pipe gulp.dest './www/images/'
    .pipe connect.reload()

gulp.task 'fonts', ->
  gulp.src paths.fonts
    .pipe gulp.dest './www/fonts/'
    .pipe connect.reload()

gulp.task 'build', (callback) ->
  runSequence 'clean', 'bower',
    ['scss', 'coffee', 'images', 'fonts'],
    'jade',
    callback

gulp.task 'watch', ['build'], ->
  gulp.watch paths.scss, ['scss']
  gulp.watch paths.coffee, ['coffee']
  gulp.watch paths.views_all, ['jade']
  gulp.watch paths.images, ['images']
  gulp.watch paths.fonts, ['fonts']

gulp.task 'server', ->
  opts = options().server
  connect.server opts
  gutil.log 'open link'
  gulp.src("./www/about.html")
    .pipe open("", url: "http://#{opts.host}:#{opts.port}")

# GLOBAL TASKS
gulp.task 'default', ['build']

gulp.task 'serve', (callback) ->
  runSequence 'dev', 'watch', 'server', callback

