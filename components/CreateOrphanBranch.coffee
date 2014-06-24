noflo = require 'noflo'
octo = require 'octo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Create an orphaned branch if it doesn\'t exist'
  c.inPorts.add 'branch',
    datatype: 'string'
    description: 'Branch name'
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['branch', 'repository']
    params: ['token']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token c.params.token if c.params.token

    # First check if the branch already exists
    branchReq = api.get "/repos/#{data.repository}/branches/#{data.branch}"
    branchReq.on 'success', (branchRes) ->
      out.send data.branch
      callback()
    branchReq.on 'error', ->
      # Missing branch, we need to create an empty commit, and then a reference to it

      commitReq = api.post "/repos/#{data.repository}/git/commits",
        message: 'Initial'
        tree: '4b825dc642cb6eb9a060e54bf8d69288fbee4904'
        parents: []
      commitReq.on 'success', (commitRes) ->

        refReq = api.post "/repos/#{data.repository}/git/refs",
          ref: "refs/heads/#{data.branch}"
          sha: commitRes.body.sha
        refReq.on 'success', (refRes) ->
          out.send data.branch
          callback()
        refReq.on 'error', (error) ->
          callback error.body
        do refReq

      commitReq.on 'error', (error) ->
        callback error.body
      do commitReq
    do branchReq

  c
