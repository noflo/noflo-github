component = require "../components/CreateOrphanBranch"
socket = require('noflo').internalSocket
octo = require 'octo'

setupComponent = ->
  c = component.getComponent()
  branch = socket.createSocket()
  repo = socket.createSocket()
  token = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.branch.attach branch
  c.inPorts.repository.attach repo
  c.inPorts.token.attach token
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  [c, branch, repo, token, out, err]

exports['test creating a missing branch'] = (test) ->
  [c, branch, repo, token, out, err] = setupComponent()
  testBranch = "branch_#{Date.now()}"

  out.once 'data', (data) ->
    test.equal data, testBranch
    test.done()

  err.once 'data', (data) ->
    test.ok false, 'Got an error'
    test.done()

  token.send process.env.GITHUB_API_TOKEN
  repo.send 'the-domains/example.net'
  branch.send testBranch

exports['test creating an existing branch'] = (test) ->
  [c, branch, repo, token, out, err] = setupComponent()

  out.once 'data', (data) ->
    test.equal data, 'master'
    test.ok data
    test.done()

  err.once 'data', (data) ->
    test.ok false, 'Got an error'
    test.done()

  token.send process.env.GITHUB_API_TOKEN
  repo.send 'the-domains/example.net'
  branch.send 'master'


exports['test creating a branch to a newly-initialized repo'] = (test) ->
  [c, branch, repo, token, out, err] = setupComponent()
  api = octo.api()
  api.token process.env.GITHUB_API_TOKEN

  setUp = (callback) ->
    request = api.post "/orgs/the-domains/repos",
      name: "example.com"
      private: false
      has_issues: false
      has_wiki: false
      has_downloads: false
      auto_init: true
    request.on 'success', (res) ->
      callback()
    request.on 'error', (err) ->
      callback()
    do request

  tearDown = (test) ->
    request = api.del "/repos/the-domains/example.com"
    request.on 'success', ->
      test.done()
    request.on 'error', (err) ->
      test.done()
    do request

  out.once 'data', (data) ->
    console.log 'success'
    test.equal data, 'grid-pages'
    test.ok data
    tearDown test

  err.once 'data', (data) ->
    console.log 'error', data
    test.ok false, 'Got an error'
    tearDown test

  setUp (err) ->
    token.send process.env.GITHUB_API_TOKEN
    repo.send 'the-domains/example.com'
    branch.send 'grid-pages'
