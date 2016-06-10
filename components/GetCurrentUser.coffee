noflo = require 'noflo'
octo = require 'octo'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'token',
    datatype: 'string'
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'token'
    out: 'out'
    forwardGroups: true
    async: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token data
    request = api.get "/user"
    request.on 'success', (res) =>
      out.send res.body
      do callback
    request.on 'error', (err) =>
      callback err.error or err.body
    do request
