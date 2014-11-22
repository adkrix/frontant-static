dev = false
root_dev = '.tmp'
root_test = '.tmp'
root_build = 'dist'
root_archives = 'archives'

# ORDER OF TASKS
runSequence = require 'run-sequence'
# components
mainBowerFiles = require 'main-bower-files'
# GULP
gulp = require 'gulp'
gutil = require 'gulp-util'
clean = require 'gulp-clean'
concat = require 'gulp-concat'
zip = require 'gulp-zip'

# SERVER
connect = require 'gulp-connect'
open = require 'gulp-open'
# CSS
scss = require 'gulp-sass'
bourbon = require 'node-bourbon'
# JAVASCRIPT
coffee = require 'gulp-coffee'
sourcemaps = require 'gulp-sourcemaps'
uglify = require 'gulp-uglify'

# HTML
jade = require 'gulp-jade'
inject = require 'gulp-inject'
injectString = require 'gulp-inject-string'

root = ->
  if dev then root_dev else root_build

base = (paths = '') ->
  if Array.isArray(paths)
    paths.map (path) -> "./#{root()}/#{path}"
  else
    "./#{root()}/#{paths}"

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

sassIncludePaths = [].concat(
  bourbon.includePaths,
  './bower_components/bootstrap-sass-twbs/assets/stylesheets/'
)

options = ->
  scss:
    errLogToConsole: true
    imagePath: '../images'
    includePaths: sassIncludePaths
    outputStyle: if dev then 'expanded' else 'compressed'
  server:
    port: 9001,
    host: 'localhost'
    root: root_dev
    livereload: true
  inject:
    ignorePath: root()
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
  gulp.src base(), {read: false}
  .pipe clean(force: true)

gulp.task 'bower', ->
  gulp.src mainBowerFiles(), options().mainBowerFiles
    .pipe gulp.dest(base('components'))
    .on 'error', on_error

gulp.task 'scss', (done) ->
  gulp.src paths.scss
    .pipe scss(options().scss)
    .pipe gulp.dest(base('styles'))
    .pipe connect.reload()
    .on 'end', done
  return

gulp.task 'coffee', ->
  gulp.src paths.coffee
    .pipe if dev then sourcemaps.init() else gutil.noop()
    .pipe coffee(bare: true)
    .on 'error', on_error
    # production: js to one file and uglify
    .pipe if dev then gutil.noop() else concat('app.js', {newLine: ';'})
    .pipe if dev then gutil.noop() else uglify()
    .pipe if dev then sourcemaps.write('../maps/') else gutil.noop()
    .pipe gulp.dest(base('scripts'))
    .pipe connect.reload()

gulp.task 'images', ->
  gulp.src paths.images
    .pipe gulp.dest(base('images'))
    .pipe connect.reload()

gulp.task 'fonts', ->
  gulp.src paths.fonts
    .pipe gulp.dest(base('fonts'))
    .pipe connect.reload()

gulp.task 'jade', ->
  gulp.src paths.views
    .pipe jade(pretty: true)
    .pipe injectString.before('</head>', '    <!-- inject:css -->\n    <!-- endinject -->\n')
    .pipe injectString.before('</body>', '    <!-- inject:js -->\n    <!-- endinject -->\n')
    .pipe inject(gulp.src(base(paths.inject_css), {read: false}), options().inject)
    .pipe inject(gulp.src(base(paths.inject_js), {read: false}), options().inject)
    .pipe gulp.dest(base())
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
  gulp.src "./#{root_dev}/index.html"
    .pipe open("", url: "http://#{opts.host}:#{opts.port}")


gulp.task 'zipping', ->
  pad = (n) -> ("0" + n).slice(-2)
  d = new Date()
  fname = "#{d.getFullYear()}-#{pad(d.getMonth()+1)}-#{pad(d.getDate())}_"
  fname += "#{pad(d.getHours())}-#{pad(d.getMinutes())}-#{pad(d.getSeconds())}.zip"
  gulp.src("#{root_build}/**/*.*")
    .pipe(zip(fname))
    .pipe(gulp.dest(root_archives))

# GLOBAL TASKS
gulp.task 'default', ['build']

gulp.task 'serve', (callback) ->
  runSequence 'dev', 'watch', 'server', callback

gulp.task 'zip', (callback) ->
  runSequence 'build', 'zipping', callback
