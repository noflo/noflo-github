noflo = require 'noflo'
octo = require 'octo'

unless noflo.isBrowser()
  btoa = require 'btoa'
else
  btoa = window.btoa

exports.getComponent = ->
  c = new noflo.Component
  c.params.branch = 'master'
  c.description = 'Create or update a file in the repository'
  c.sendRepo = true
  c.inPorts.add 'in',
    datatype: 'string'
    description: 'File contents to push'
    required: true
  c.inPorts.add 'message',
    datatype: 'string'
    description: 'Commit message'
    required: true
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
    required: true
  c.inPorts.add 'path',
    datatype: 'string'
    description: 'File path inside repository'
    required: true
  c.inPorts.add 'branch',
    datatype: 'string'
    description: 'Git branch to use'
    required: true
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    required: true
  c.inPorts.add 'sendrepo',
    datatype: 'boolean'
    description: 'Whether to send repository path as group'
    default: true
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: ['in', 'message', 'repository', 'path']
    params: ['token', 'branch', 'sendrepo']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token c.params.token if c.params.token
    sendRepo = c.params.sendrepo or false

    # Start by getting the SHA
    shaReq = api.get "/repos/#{data.repository}/contents/#{data.path}?ref=#{c.params.branch}"
    shaReq.on 'success', (shaRes) ->
      # SHA found, update
      updateReq = api.put "/repos/#{data.repository}/contents/#{data.path}",
        path: data.path
        message: data.message
        content: btoa unescape encodeURIComponent data.in
        sha: shaRes.body.sha
        branch: c.params.branch
      updateReq.on 'success', (updateRes) ->
        # File was updated
        out.beginGroup data.repository if sendRepo
        out.beginGroup data.path
        out.send updateRes.body.commit.sha
        out.endGroup()
        out.endGroup() if sendRepo
        do callback
      updateReq.on 'error', (error) ->
        callback error.error or error.body
      do updateReq

    shaReq.on 'error', ->
      # No SHA found, create as new file
      createReq = api.put "/repos/#{data.repository}/contents/#{data.path}",
        path: data.path
        message: data.message
        content: btoa unescape encodeURIComponent data.in
        branch: c.params.branch
      createReq.on 'success', (createRes) ->
        # File was created
        out.beginGroup data.repository if sendRepo
        out.beginGroup data.path
        out.send createRes.body.commit.sha
        out.endGroup()
        out.endGroup() if sendRepo
        do callback
      createReq.on 'error', (error) ->
        callback error.error or error.body
      do createReq
    do shaReq
