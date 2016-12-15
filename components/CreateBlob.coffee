noflo = require 'noflo'
github = require 'github'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Create a new Git blob'
  c.inPorts.add 'content',
    datatype: 'string'
    description: 'Blob contents as a UTF-8 encoded string'
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    required: true
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['content', 'repository']
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

    [org, repoName] = data.repository.split '/'
    api.gitdata.createBlob
      owner: org
      repo: repoName
      content: data.content
      encoding: 'utf-8'
    , (err, res) ->
      return callback err if err
      out.send res.sha
      do callback
