noflo = require 'noflo'
octo = require 'octo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Create a repository'
  c.inPorts.add 'in',
    datatype: 'string'
    description: 'Repository name'
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

    request = api.post '/user/repos',
      name: data

    request.on 'success', (res) ->
      out.beginGroup data
      out.send res.body
      out.endGroup()
      callback()
    request.on 'error', (err) ->
      callback err.body
    do request

  noflo.helpers.MultiError c

  c
