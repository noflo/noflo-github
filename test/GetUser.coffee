component = require "../components/GetUser"
socket = require('noflo').internalSocket

setupComponent = ->
  c = component.getComponent()
  user = socket.createSocket()
  token = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.user.attach user
  c.inPorts.token.attach token
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  [c, user, token, out, err]

exports['test reading a valid user'] = (test) ->
  [c, user, token, out, err] = setupComponent()
  out.once 'data', (data) ->
    test.ok data, 'We should receive user object'
    test.ok data.login, 'Users should have logins'
    test.ok data.name, 'Users should have real names'
    test.done()
  err.once 'data', (data) ->
    test.ok false, 'We should have gotten a result'
    test.done()

  token.send process.env.GITHUB_API_TOKEN
  user.send 'bergie'
