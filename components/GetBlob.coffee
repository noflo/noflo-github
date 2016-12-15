noflo = require 'noflo'
github = require 'github'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Get a git blob'
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
    required: true
  c.inPorts.add 'sha',
    datatype: 'string'
    description: 'Blob SHA'
    required: true
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    required: true
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['repository', 'sha']
    params: ['token']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = new github
    unless c.params.token
      return callback new Error 'token required'
    api.authenticate
      type: 'token'
      token: c.params.token

    [org, repoName] = data.repository.split '/'
    api.gitdata.getBlob
      owner: org
      repo: repoName
      sha: data.sha
    , (err, res) ->
      return callback err if err
      return callback new Error 'no result available' unless res
      out.beginGroup data.repository
      out.beginGroup data.sha
      out.send res.body
      out.endGroup()
      out.endGroup()
      do callback
