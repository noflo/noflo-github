component = require "../components/CreateOrphanBranch"
socket = require('noflo').internalSocket

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
