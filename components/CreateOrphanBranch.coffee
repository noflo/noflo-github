noflo = require 'noflo'
github = require 'github'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Create an orphaned branch if it doesn\'t exist'
  c.inPorts.add 'branch',
    datatype: 'string'
    description: 'Branch name'
    required: true
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
    required: true
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    required: true
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'

  c.getApi = -> new github

  noflo.helpers.WirePattern c,
    in: ['branch', 'repository']
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
    # First check if the branch already exists
    api.repos.getBranch
      owner: org
      repo: repoName
      branch: data.branch
    , (err) ->
      unless err
        out.send data.branch
        do callback
        return
      # Missing branch, we need to create an empty commit, and then a reference to it
      api.gitdata.createTree
        owner: org
        repo: repoName
        tree: [
          path: 'README.md'
          content: data.branch
          mode: '100644'
          type: 'blob'
        ]
      , (err, tree) ->
        return callback err if err
        return callback new Error 'No SHA' unless tree.sha

        api.gitdata.createCommit
          owner: org
          repo: repoName
          message: 'Initial'
          tree: tree.sha
          parents: []
        , (err, commit) ->
          return callback err if err
          return callback new Error 'No commit SHA' unless commit.sha

          api.gitdata.createReference
            owner: org
            repo: repoName
            ref: "refs/heads/#{data.branch}"
            sha: commit.sha
          , (err) ->
            return callback err if err
            out.send data.branch
            callback()
