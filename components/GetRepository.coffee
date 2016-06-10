noflo = require 'noflo'
octo = require 'octo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Get information about a repository'
  c.inPorts.add 'in',
    datatype: 'string'
    description: 'Repository path'
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: ['in']
    params: ['token']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = octo.api()
    unless c.params.token
      return callback new Error 'token required'
    api.token c.params.token

    request = api.get "/repos/#{data}"
    request.on 'success', (res) ->
      out.beginGroup data
      out.send res.body
      out.endGroup()
      callback()
    request.on 'error', (err) ->
      callback new Error err.body?.error
    do request
