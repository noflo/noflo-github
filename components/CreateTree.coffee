noflo = require 'noflo'
github = require 'github'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Create a GitHub tree'
  c.inPorts.add 'tree',
    datatype: 'array'
    description: 'Tree entries to create'
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
  c.inPorts.add 'base',
    datatype: 'string'
    description: 'Base tree to create the tree for'
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    required: true
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['tree', 'repository']
    params: ['token', 'base']
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
    api.gitdata.createTree
      owner: org
      repo: repoName
      tree: data.tree
      base_tree: c.params.base
    , (err, res) ->
      return callback err if err
      out.send res
      do callback
