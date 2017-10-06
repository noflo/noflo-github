noflo = require 'noflo'
github = require 'github'

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
    api = new github
    unless c.params.token
      return callback new Error 'token required'
    api.authenticate
      type: 'token'
      token: c.params.token
    api.users.getForUser
      username: data
    , (err, res) ->
      return callback err if err
      out.send res
      do callback
