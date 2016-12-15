noflo = require 'noflo'
github = require 'github'
atob = require 'atob'

exports.getComponent = ->
  c = new noflo.Component
  c.ref = 'master'
  c.description = 'Get contents of a file or a directory'
  c.sendRepo = true
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
    required: true
  c.inPorts.add 'path',
    datatype: 'string'
    description: 'File path inside repository'
    required: true
  c.inPorts.add 'ref',
    datatype: 'string'
    description: 'The name of the commit/branch/tag'
    process: (event, payload) ->
      c.ref = payload if event is 'data'
    required: true
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    required: true
  c.inPorts.add 'sendrepo',
    datatype: 'boolean'
    description: 'Whether to send repository path as group'
    default: true
    process: (event, payload) ->
      return unless event is 'data'
      c.sendRepo = String(payload) is 'true'
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'files',
    datatype: 'object'
    required: false
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: ['repository', 'path']
    params: ['token']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = new github
    if c.params.token
      api.authenticate
        type: 'token'
        token: c.params.token

    [org, repoName] = data.repository.split '/'
    api.repos.getContent
      owner: org
      repo: repoName
      path: data.path
      ref: c.ref
    , (err, res) ->
      return callback err if err
      unless res.content
        unless toString.call(res) is '[object Array]'
          callback new Error 'content not found'
          return
        # Directory, send file paths
        c.outPorts.files.beginGroup data.repository if c.sendRepo
        for file in res
          c.outPorts.files.send file
        c.outPorts.files.endGroup() if c.sendRepo
        c.outPorts.files.disconnect()
        do callback
        return
      out.beginGroup data.repository if c.sendRepo
      out.beginGroup data.path
      out.send decodeURIComponent escape atob res.content.replace /\s/g, ''
      out.endGroup()
      out.endGroup() if c.sendRepo
      do callback
