noflo = require 'noflo'
octo = require 'octo'

unless noflo.isBrowser()
  btoa = require 'btoa'
else
  btoa = window.btoa

exports.getComponent = ->
  c = new noflo.Component
  c.branch = 'master'
  c.description = 'Create or update a file in the repository'
  c.inPorts.add 'in',
    datatype: 'string'
    description: 'File contents to push'
  c.inPorts.add 'message',
    datatype: 'string'
    description: 'Commit message'
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
  c.inPorts.add 'path',
    datatype: 'string'
    description: 'File path inside repository'
  c.inPorts.add 'branch',
    datatype: 'string'
    description: 'Git branch to use'
    process: (event, payload) ->
      c.branch = payload if event is 'data'
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: ['in', 'message', 'repository', 'path']
    params: ['token']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token c.params.token if c.params.token

    # Start by getting the SHA
    shaReq = api.get "/repos/#{data.repository}/contents/#{data.path}?ref=#{c.branch}"
    shaReq.on 'success', (shaRes) ->
      # SHA found, update
      updateReq = api.put "/repos/#{data.repository}/contents/#{data.path}",
        path: data.path
        message: data.message
        content: btoa data.in
        sha: shaRes.body.sha
        branch: c.branch
      updateReq.on 'success', (updateRes) ->
        # File was updated
        out.beginGroup data.path
        out.send updateRes.body.commit.sha
        out.endGroup()
        do callback
      updateReq.on 'error', (error) ->
        callback error.body
      do updateReq

    shaReq.on 'error', ->
      # No SHA found, create as new file
      createReq = api.put "/repos/#{data.repository}/contents/#{data.path}",
        path: data.path
        message: data.message
        content: btoa data.in
        branch: c.branch
      createReq.on 'success', (createRes) ->
        # File was created
        out.beginGroup data.path
        out.send createRes.body.commit.sha
        out.endGroup()
        do callback
      createReq.on 'error', (error) ->
        callback error.body
      do createReq
    do shaReq

  c
