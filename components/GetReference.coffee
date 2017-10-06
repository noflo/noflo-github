noflo = require 'noflo'
github = require 'github'

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
    api = new github
    if c.params.token
      api.authenticate
        type: 'token'
        token: c.params.token

    ref = c.params?.reference or 'heads/master'

    [org, repoName] = data.repository.split '/'
    api.gitdata.getReference
      owner: org
      repo: repoName
      ref: ref
    , (err, res) ->
      return callback err if err
      unless res
        callback new Error 'No result received'
        return
      out.beginGroup repository
      out.beginGroup ref
      out.send res
      out.endGroup()
      out.endGroup()
      do callback
