noflo = require 'noflo'
octo = require 'octo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Create a new Git blob'
  c.inPorts.add 'content',
    datatype: 'string'
    description: 'Blob contents as a UTF-8 encoded string'
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
    in: ['content', 'repository']
    params: ['token']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token c.params.token if c.params.token

    req = api.post "/repos/#{data.repository}/git/blobs",
      content: data.content
      encoding: 'utf-8'
    req.on 'success', (res) ->
      out.send res.body.sha
      do callback
    req.on 'error', (err) ->
      callback err.body
    do req

  c
