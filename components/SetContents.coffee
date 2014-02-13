noflo = require 'noflo'
octo = require 'octo'

unless noflo.isBrowser()
  btoa = require 'btoa'
else
  btoa = window.btoa

class SetContents extends noflo.AsyncComponent
  description: 'Create or update a file in the repository'

  constructor: ->
    @token = null
    @message = null
    @repo = null
    @path = null

    @inPorts =
      in: new noflo.Port 'string'
      token: new noflo.Port 'string'
      message: new noflo.Port 'string'
      repository: new noflo.Port 'string'
      path: new noflo.Port 'string'
    @outPorts =
      out: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.token.on 'data', (@token) =>
    @inPorts.message.on 'data', (@message) =>
    @inPorts.repository.on 'data', (@repo) =>
    @inPorts.path.on 'data', (@path) =>

    super 'in'

  doAsync: (contents, callback) ->
    unless @repo
      callback new Error 'repository name required'
    unless @path
      callback new Error 'file path required'
    @message = '' unless @message

    repo = @repo
    path = @path
    message = @message

    api = octo.api()
    api.token @token if @token

    # Start by getting the SHA
    shaReq = api.get "/repos/#{repo}/contents/#{path}"
    shaReq.on 'success', (shaRes) =>
      # SHA found, update
      updateReq = api.put "/repos/#{repo}/contents/#{path}",
        path: path
        message: message
        content: btoa contents
        sha: shaRes.body.sha
      updateReq.on 'success', (updateRes) =>
        # File was updated
        @outPorts.out.beginGroup path
        @outPorts.out.send updateRes.sha
        @outPorts.out.endGroup()
        @outPorts.out.disconnect()
        do callback
      updateReq.on 'error', (error) =>
        @outPorts.out.disconnect()
        callback err.body
      do updateReq

    shaReq.on 'error', =>
      # No SHA found, create as new file
      createReq = api.put "/repos/#{repo}/contents/#{path}",
        path: path
        message: message
        content: btoa contents
      createReq.on 'success', (createRes) =>
        # File was updated
        @outPorts.out.beginGroup path
        @outPorts.out.send createRes.sha
        @outPorts.out.endGroup()
        @outPorts.out.disconnect()
        do callback
      createReq.on 'error', (error) =>
        @outPorts.out.disconnect()
        callback err.body
      do createReq
    
    @outPorts.out.connect()
    do shaReq

exports.getComponent = -> new SetContents
