noflo = require 'noflo'
octo = require 'octo'

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
    scoped: false
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
    api = octo.api()
    api.token c.params.token if c.params.token

    req = api.post "/repos/#{data.repository}/git/trees",
      tree: data.tree
      base_tree: c.params.base
    req.on 'success', (res) ->
      out.send res.body
      do callback
    req.on 'error', (err) ->
      callback err.error or err.body
    do req
