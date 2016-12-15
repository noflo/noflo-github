noflo = require 'noflo'
github = require 'github'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Create a GitHub commit'
  c.inPorts.add 'message',
    datatype: 'string'
    description: 'Commit message'
  c.inPorts.add 'tree',
    datatype: 'string'
    description: 'Tree SHA'
  c.inPorts.add 'parents',
    datatype: 'array'
    description: 'Parent commits'
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    required: true
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['message', 'tree', 'parents', 'repository']
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
    api.gitdata.createCommit
      owner: org
      repo: repoName
      message: data.message
      tree: data.tree
      parents: data.parents or []
    , (err, res) ->
      return callback err if err
      out.send res.sha
      do callback
