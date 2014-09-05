noflo = require 'noflo'
octo = require 'octo'

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
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['message', 'tree', 'parents', 'repository']
    params: ['token']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token c.params.token if c.params.token

    req = api.post "/repos/#{data.repository}/git/commits",
      message: data.message
      tree: data.tree
      parents: data.parents or []
    req.on 'success', (res) ->
      out.send res.body.sha
      do callback
    req.on 'error', (err) ->
      callback err.body
    do req

  c
