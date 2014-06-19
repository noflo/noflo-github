noflo = require 'noflo'
octo = require 'octo'

unless noflo.isBrowser()
  btoa = require 'btoa'
else
  btoa = window.btoa

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Create or update a file in the repository'
  c.token = null
  c.inPorts.add 'in',
    datatype: 'string'
    description: 'File contents to push'
  c.inPorts.add 'message',
    datatype: 'string'
    description: 'Commit message'
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    process: (event, payload) ->
      c.token = payload if event is 'data'
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: ['in', 'message', 'repository', 'path']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token c.token if c.token

    # Start by getting the SHA
    shaReq = api.get "/repos/#{data.repository}/contents/#{data.path}"
    shaReq.on 'success', (shaRes) =>
      # SHA found, update
      updateReq = api.put "/repos/#{data.repository}/contents/#{data.path}",
        path: data.path
        message: data.message
        content: btoa data.in
        sha: shaRes.body.sha
      updateReq.on 'success', (updateRes) =>
        # File was updated
        out.beginGroup data.path
        out.send updateRes.sha
        out.endGroup()
        do callback
      updateReq.on 'error', (error) =>
        callback err.body
      do updateReq

    shaReq.on 'error', =>
      # No SHA found, create as new file
      updateReq = api.put "/repos/#{data.repository}/contents/#{data.path}",
        path: data.path
        message: data.message
        content: btoa data.in
      createReq.on 'success', (createRes) =>
        # File was created
        out.beginGroup data.path
        out.send createRes.sha
        out.endGroup()
        do callback
      createReq.on 'error', (error) =>
        callback err.body
      do createReq
    do shaReq

  c
