noflo = require 'noflo'
octo = require 'octo'

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
    scoped: false
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
    api = octo.api()
    api.token c.params.token if c.params.token

    request = api.get "/repos/#{data.repository}/git/blobs/#{data.sha}"
    request.on 'success', (res) ->
      unless res.body
        return callback new Error 'no result available'
      out.beginGroup data.repository
      out.beginGroup data.sha
      out.send res.body
      out.endGroup()
      out.endGroup()
      do callback
    request.on 'error', (err) ->
      callback err.error or err.body
    do request
