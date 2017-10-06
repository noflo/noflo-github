noflo = require 'noflo'
github = require 'github'

sendBatch = (api, data, res, out, callback, grouped) ->
  unless grouped
    out.beginGroup data
    grouped = true

  unless res.length
    out.endGroup() if grouped
    return callback()

  out.send user for user in res

  unless api.hasNextPage res
    out.endGroup() if grouped
    callback()
    return

  api.getNextPage res, {}, (err, next) ->
    return callback err if err
    sendBatch api, data, next, out, callback, grouped

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
    api = new github
    unless c.params.token
      return callback new Error 'token required'
    api.authenticate
      type: 'token'
      token: c.params.token

    grouped = false

    [org, repoName] = data.split '/'
    api.activity.getStargazersForRepo
      owner: org
      repo: repoName
    , (err, res) ->
      return callback err if err
      sendBatch api, data, res, out, callback, grouped
