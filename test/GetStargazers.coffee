component = require "../components/GetStargazers"
socket = require('noflo').internalSocket

setupComponent = ->
  c = component.getComponent()
  repo = socket.createSocket()
  token = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.repository.attach repo
  c.inPorts.token.attach token
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  [c, repo, token, out, err]

exports['test reading for valid repo'] = (test) ->
  [c, repo, token, out, err] = setupComponent()

  expected = 200
  received = 0
  out.on 'data', (data) ->
    received++
    test.ok data, 'We should receive user objects'
    test.ok data.login, 'Users should have logins'
  out.once 'disconnect', ->
    test.ok (received >= expected), 'We should get at least 200 stargazers'
    test.done()

  token.send process.env.GITHUB_API_TOKEN
  repo.send 'noflo/noflo'
