noflo = require 'noflo'
octo = require 'octo'

unless noflo.isBrowser()
  atob = require 'atob'
else
  atob = window.atob

class GetContents extends noflo.AsyncComponent
  description: 'Get contents of a file or a directory'
  constructor: ->
    @token = null
    @repo = null
    @sendRepo = true

    @inPorts =
      repository: new noflo.Port 'string'
      path: new noflo.Port 'string'
      token: new noflo.Port 'string'
      sendrepo: new noflo.Port 'boolean'
    @outPorts =
      out: new noflo.Port 'string'
      files: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.repository.on 'data', (data) =>
      @repo = data

    @inPorts.sendrepo.on 'data', (@sendRepo) =>

    @inPorts.token.on 'data', (data) =>
      @token = data

    super 'path'

  doAsync: (path, callback) ->
    api = octo.api()
    api.token @token if @token

    unless @repo
      callback new Error 'repository name required'
    repo = @repo

    request = api.get "/repos/#{repo}/contents/#{path}"
    request.on 'success', (res) =>
      unless res.body.content
        unless toString.call(res.body) is '[object Array]'
          callback new Error 'content not found'
          return
        unless @outPorts.files.isAttached()
          callback new Error 'content not found'
          return
        # Directory, send file paths
        @outPorts.files.beginGroup repo if @sendRepo
        for file in res.body
          @outPorts.files.send file
        @outPorts.files.endGroup() if @sendRepo
        @outPorts.files.disconnect()
        callback()
        return
      @outPorts.out.beginGroup repo if @sendRepo
      @outPorts.out.beginGroup path
      @outPorts.out.send atob res.body.content.replace /\s/g, ''
      @outPorts.out.endGroup()
      @outPorts.out.endGroup() if @sendRepo
      @outPorts.out.disconnect()
      callback()
    request.on 'error', (err) =>
      @outPorts.out.disconnect()
      callback err.body
    @outPorts.out.connect()
    do request

exports.getComponent = -> new GetContents
