noflo = require 'noflo'
github = require 'github'

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
    api = new github
    unless c.params.token
      return callback new Error 'token required'
    api.authenticate
      type: 'token'
      token: c.params.token

    ref = c.params?.reference or 'heads/master'
    force = String(c.params?.force) is 'true'
    ref = ref.substr 5 if ref.substr(0, 5) is 'refs/'

    [org, repoName] = data.repository.split '/'
    api.gitdata.updateReference
      owner: org
      repo: repoName
      ref: ref
      sha: data.commit
      force: false
    , (err, res) ->
      return callback err if err
      out.send res.body
      do callback
