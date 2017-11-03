noflo = require 'noflo'
octo = require 'octo'

unless noflo.isBrowser()
  atob = require 'atob'
else
  atob = window.atob

exports.getComponent = ->
  c = new noflo.Component
  c.params.ref = 'master'
  c.description = 'Get contents of a file or a directory'
  c.sendRepo = true
  c.inPorts.add 'repository',
    datatype: 'string'
    description: 'Repository path'
    required: true
  c.inPorts.add 'path',
    datatype: 'string'
    description: 'File path inside repository'
    required: true
  c.inPorts.add 'ref',
    datatype: 'string'
    description: 'The name of the commit/branch/tag'
    required: true
  c.inPorts.add 'token',
    datatype: 'string'
    description: 'GitHub API token'
    required: true
  c.inPorts.add 'sendrepo',
    datatype: 'boolean'
    description: 'Whether to send repository path as group'
    default: true
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'files',
    datatype: 'object'
    required: false
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: ['repository', 'path']
    params: ['token', 'sendrepo', 'ref']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    api = octo.api()
    api.token c.params.token if c.params.token
    sendRepo = c.params.sendrepo or false

    request = api.get "/repos/#{data.repository}/contents/#{data.path}?ref=#{c.params.ref}"
    request.on 'success', (res) ->
      unless res.body.content
        unless toString.call(res.body) is '[object Array]'
          callback new Error 'content not found'
          return
        # Directory, send file paths
        c.outPorts.files.beginGroup data.repository if sendRepo
        for file in res.body
          c.outPorts.files.send file
        c.outPorts.files.endGroup() if sendRepo
        c.outPorts.files.disconnect()
        do callback
        return
      out.beginGroup data.repository if c.sendRepo
      out.beginGroup data.path
      out.send decodeURIComponent escape atob res.body.content.replace /\s/g, ''
      out.endGroup()
      out.endGroup() if c.sendRepo
      do callback
    request.on 'error', (err) ->
      callback err.error or err.body
    do request
