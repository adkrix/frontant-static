dev = false
# ORDER OF TASKS
runSequence = require 'run-sequence'
# components
mainBowerFiles = require 'main-bower-files'
# GULP
gulp = require 'gulp'
gutil = require 'gulp-util'
clean = require 'gulp-clean'
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

dir = (path = '') ->

  mkdir = (path) ->
    if dev
      "./www/#{path}"
    else
      "./dist/#{path}"

  if Array.isArray(path)
    path.map mkdir
  else
    mkdir path



paths =
  fonts: [
    './app/fonts/**/*.*'
  ]
  scss: [
    './app/styles/**/*.scss' 
  ]
  coffee: [
    './app/scripts/**/*.coffee'
  ]
  views: [
    './app/views/*.jade'
  ]
  views_all: [
    './app/views/**/*.jade'
  ]
  images: [
    './app/images/**/*.*'
  ]
  inject_js: [
    'components/jquery/dist/jquery.js'
    'components/**/*.js'
    'scripts/**/*.js'
  ]
  inject_css: [
    'components/**/*.css'
    'styles/**/*.css'
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
  inject:
    ignorePath: if dev then 'www' else 'dist'
    relative: false
  mainBowerFiles:
    base: 'bower_components'

on_error = (error) ->
  gutil.beep()
  gutil.log error


# TASKS
gulp.task 'dev', ->
  dev = true

gulp.task 'clean', ->
  gulp.src dir(), {read: false}
  .pipe clean(force: true)

gulp.task 'bower', ->
  gulp.src mainBowerFiles(), options().mainBowerFiles
    .pipe gulp.dest(dir('components'))
    .on 'error', on_error

gulp.task 'scss', (done) ->
  gulp.src paths.scss
    .pipe scss(options().scss)
    .pipe gulp.dest(dir('styles'))
    .pipe connect.reload()
    .on 'end', done
  return

gulp.task 'coffee', ->
  gulp.src paths.coffee
    .pipe sourcemaps.init()
    .pipe coffee(bare: true)
    .on 'error', on_error
    .pipe gulp.dest(dir('scripts'))
    .pipe sourcemaps.write('../maps/')
    .pipe connect.reload()

gulp.task 'images', ->
  gulp.src paths.images
    .pipe gulp.dest(dir('images'))
    .pipe connect.reload()

gulp.task 'fonts', ->
  gulp.src paths.fonts
    .pipe gulp.dest(dir('fonts'))
    .pipe connect.reload()

gulp.task 'jade', ->
  gulp.src paths.views
    .pipe jade(pretty: true)
    .pipe injectString.before('</head>', '    <!-- inject:css -->\n    <!-- endinject -->\n')
    .pipe injectString.before('</body>', '    <!-- inject:js -->\n    <!-- endinject -->\n')
    .pipe inject(gulp.src(dir(paths.inject_css), {read: false}), options().inject)
    .pipe inject(gulp.src(dir(paths.inject_js), {read: false}), options().inject)
    .pipe gulp.dest(dir())
    .pipe connect.reload()

gulp.task 'build', (callback) ->
  runSequence 'clean', 'bower', ['scss', 'coffee', 'images', 'fonts'], 'jade', callback

gulp.task 'watch', ['build'], ->
  gulp.watch paths.scss, ['scss']
  gulp.watch paths.coffee, ['coffee']
  gulp.watch paths.views_all, ['jade']
  gulp.watch paths.images, ['images']
  gulp.watch paths.fonts, ['fonts']

gulp.task 'server', ->
  opts = options().server
  connect.server opts
  gulp.src './www/index.html'
    .pipe open("", url: "http://#{opts.host}:#{opts.port}")

# GLOBAL TASKS
gulp.task 'default', ['build']

gulp.task 'serve', (callback) ->
  runSequence 'dev', 'watch', 'server', callback

