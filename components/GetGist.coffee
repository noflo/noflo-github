noflo = require 'noflo'
github = require 'github'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'gist',
    datatype: 'string'
    description: 'Gist ID'
    required: true
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    required: false
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: 'gist'
    out: 'out'
    params: ['token']
    async: true
    forwardGroups: true
  , (id, groups, out, callback) ->
    api = new github
    if c.params.token
      api.authenticate
        type: 'token'
        token: c.params.token
    api.gists.get
      id: id
    , (err, res) ->
      return callback err if err
      unless res
        callback new Error 'No result received'
        return
      out.beginGroup id
      out.send res
      out.endGroup id
      callback()
