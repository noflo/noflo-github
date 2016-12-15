noflo = require 'noflo'
github = require 'github'
btoa = require 'btoa'

exports.getComponent = ->
  c = new noflo.Component
  c.branch = 'master'
  c.description = 'Create or update a file in the repository'
  c.sendRepo = true
  c.inPorts.add 'in',
    datatype: 'string'
    description: 'File contents to push'
    required: true
  c.inPorts.add 'message',
    datatype: 'string'
    description: 'Commit message'
    required: true
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
    required: true
  c.inPorts.add 'path',
    datatype: 'string'
    description: 'File path inside repository'
    required: true
  c.inPorts.add 'branch',
    datatype: 'string'
    description: 'Git branch to use'
    process: (event, payload) ->
      c.branch = payload if event is 'data'
    required: true
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    required: true
  c.inPorts.add 'sendrepo',
    datatype: 'boolean'
    description: 'Whether to send repository path as group'
    default: true
    process: (event, payload) ->
      return unless event is 'data'
      c.sendRepo = String(payload) is 'true'
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: ['in', 'message', 'repository', 'path']
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
    # Start by getting the SHA
    api.repos.getContent
      owner: org
      repo: repoName
      path: data.path
      branch: c.branch
    , (err, res) ->
      if res.sha
        # SHA found, update
        api.repos.updateFile
          owner: org
          repo: repoName
          path: data.path
          message: data.message
          content: btoa unescape encodeURIComponent data.in
          sha: res.sha
          branch: c.branch
        , (err, updated) ->
          return callback err if err
          # File was updated
          out.beginGroup data.repository if c.sendRepo
          out.beginGroup data.path
          out.send updated.commit.sha
          out.endGroup()
          out.endGroup() if c.sendRepo
          do callback
        return
      # No SHA found, create as new file
      api.repos.createFile
        owner: org
        repo: repoName
        path: data.path
        message: data.message
        content: btoa unescape encodeURIComponent data.in
        branch: c.branch
      , (err, created) ->
        return callback err if err
        # File was created
        out.beginGroup data.repository if c.sendRepo
        out.beginGroup data.path
        out.send created.commit.sha
        out.endGroup()
        out.endGroup() if c.sendRepo
        do callback
