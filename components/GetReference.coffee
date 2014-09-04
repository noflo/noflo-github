noflo = require 'noflo'
octo = require 'octo'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'repository',
    datatype: 'string'
  c.inPorts.add 'token',
    datatype: 'string'
    required: true
  c.inPorts.add 'reference',
    datatype: 'string'
    default: 'heads/master'
    required: true
  c.outPorts.add 'reference',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'repository'
    params: ['token', 'reference']
    out: 'reference'
    async: true
    forwardGroups: true
  , (repository, groups, out, callback) ->
    api = octo.api()
    api.token c.params.token if c.params?.token
    ref = c.params?.reference or 'heads/master'

    request = api.get "/repos/#{repository}/git/refs/#{ref}"
    request.on 'success', (res) ->
      unless res.body
        callback new Error 'No result received'
        return
      out.beginGroup repository
      out.beginGroup ref
      out.send res.body
      out.endGroup()
      out.endGroup()
      do callback
    request.on 'error', (err) ->
      callback err.body
    do request
  c

