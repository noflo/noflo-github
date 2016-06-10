noflo = require 'noflo'
octo = require 'octo'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'user',
    datatype: 'string'
    required: true
  c.inPorts.add 'token',
    datatype: 'string'
    required: true
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'user'
    out: 'out'
    params: ['token']
    forwardGroups: true
    async: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token c.params.token

    request = api.get "/users/#{data}"
    request.on 'success', (res) =>
      out.send res.body
      do callback
    request.on 'error', (err) =>
      callback err.body
    do request
