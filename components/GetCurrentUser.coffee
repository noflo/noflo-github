noflo = require 'noflo'
github = require 'github'

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
    api = new github
    api.authenticate
      type: 'token'
      token: data
    api.users.get {}, (err, res) ->
      return callback err if err
      out.send res
      do callback
