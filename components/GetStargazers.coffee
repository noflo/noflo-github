noflo = require 'noflo'
octo = require 'octo'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'repository',
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
    in: 'repository'
    params: ['token']
    out: 'out'
    forwardGroups: true
    async: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token c.params.token
    grouped = false
    request = api.get "/repos/#{data}/stargazers"
    request.perpage 30
    request.on 'success', (res) ->
      unless grouped
        out.beginGroup data
        grouped = true

      unless res.body.length
        out.endGroup() if grouped
        return callback()
      out.send user for user in res.body
      return request.next() if request.hasnext()
      out.endGroup() if grouped
      callback()
    request.on 'error', (err) =>
      callback err.error or err.body
    do request
