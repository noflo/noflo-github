noflo = require 'noflo'
octo = require 'octo'

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
    api = octo.api()
    api.token c.params.token if c.params?.token

    request = api.get "/gists/#{id}"
    request.on 'success', (res) ->
      unless res.body
        callback new Error 'No result received'
        return
      out.beginGroup id
      out.send res.body
      out.endGroup id
      callback()
    request.on 'error', (err) ->
      callback err.body
    do request

    c
