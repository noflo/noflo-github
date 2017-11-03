module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # Browser build of NoFlo
    noflo_browser:
      build:
        files:
          'browser/noflo-github.js': ['package.json']

    # CoffeeScript compilation
    coffee:
      spec:
        options:
          bare: true
        expand: true
        cwd: 'spec'
        src: ['**.coffee']
        dest: 'spec'
        ext: '.js'

    # Coding standards
    coffeelint:
      components:
        files:
          src: ['components/*.coffee']
        options:
          max_line_length:
            value: 80
            level: 'warn'

    # BDD tests on Node.js
    mochaTest:
      nodejs:
        src: ['spec/*.coffee']
        options:
          reporter: 'spec'
          require: 'coffeescript/register'
          grep: process.env.TESTS

    # Web server for the browser tests
    connect:
      server:
        options:
          port: 8000
    # BDD tests on browser
    mocha_phantomjs:
      all:
        options:
          output: 'spec/result.xml'
          reporter: 'spec'
          failWithOutput: true
          urls: ['http://localhost:8000/spec/runner.html']

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-noflo-browser'
  @loadNpmTasks 'grunt-contrib-coffee'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-coffeelint'
  @loadNpmTasks 'grunt-mocha-test'
  @loadNpmTasks 'grunt-contrib-connect'
  @loadNpmTasks 'grunt-mocha-phantomjs'

  # Our local tasks
  @registerTask 'build', 'Build NoFlo for the chosen target platform', (target = 'all') =>
    if target is 'all' or target is 'browser'
      @task.run 'noflo_browser'

  @registerTask 'test', 'Build NoFlo and run automated tests', (target = 'all') =>
    @task.run 'coffeelint'
    if target is 'all' or target is 'nodejs'
      @task.run 'mochaTest'
    if target is 'all' or target is 'browser'
      @task.run 'coffee'
      @task.run 'noflo_browser'
      @task.run 'connect'
      @task.run 'mocha_phantomjs'

  @registerTask 'default', ['test']
