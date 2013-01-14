component = require "../components/CreateRepository"
socket = require('noflo').internalSocket

setupComponent = ->
  c = component.getComponent()
  ins = socket.createSocket()
  token = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.in.attach ins
  c.inPorts.token.attach token
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  [c, ins, token, out, err]

exports['test creating without token'] = (test) ->
  [c, ins, token, out, err] = setupComponent()

  err.once 'data', (data) ->
    test.ok data, 'Errors are objects'
    test.ok data.message, 'There needs to be an error message'
    test.equal data.message, 'token required'

    test.done()

  ins.send 'xyz123456'
