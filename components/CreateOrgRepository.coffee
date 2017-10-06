noflo = require 'noflo'
github = require 'github'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Create organization repository'
  c.inPorts.add 'in',
    datatype: 'string'
    description: 'Repository name'
  c.inPorts.add 'org',
    datatype: 'string'
    description: 'Organization name'
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: ['in', 'org']
    params: ['token']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = new github
    unless c.params.token
      return callback new Error 'token required'
    api.authenticate
      type: 'token'
      token: c.params.token

    api.repos.createForOrg
      org: data.org
      name: data.in
    , (err, res) ->
      return callback err if err
      out.beginGroup data.in
      out.send res.body
      out.endGroup()
      do callback
