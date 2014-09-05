noflo = require 'noflo'
octo = require 'octo'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'repository',
    datatype: 'string'
  c.inPorts.add 'commit',
    datatype: 'string'
    description: 'Commit SHA'
  c.inPorts.add 'token',
    datatype: 'string'
    required: true
  c.inPorts.add 'reference',
    datatype: 'string'
    default: 'heads/master'
    required: true
  c.inPorts.add 'force',
    datatype: 'boolean'
    default: false
    required: true
  c.outPorts.add 'reference',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['repository', 'commit']
    params: ['token', 'reference', 'force']
    out: 'reference'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token c.params.token if c.params.token
    ref = c.params?.reference or 'heads/master'
    force = String(c.params?.force) is 'true'
    ref = ref.substr 5 if ref.substr(0, 5) is 'refs/'

    req = api.patch "/repos/#{data.repository}/git/refs/#{ref}",
      sha: data.commit
      force: false
    req.on 'success', (res) ->
      out.send res.body
      do callback
    req.on 'error', (err) ->
      callback err.body
    do req

  c
