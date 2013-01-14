component = require "../components/CreateOrgRepository"
socket = require('noflo').internalSocket

setupComponent = ->
  c = component.getComponent()
  ins = socket.createSocket()
  org = socket.createSocket()
  token = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.in.attach ins
  c.inPorts.org.attach org
  c.inPorts.token.attach token
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  [c, ins, org, token, out, err]

exports['test creating without organization'] = (test) ->
  [c, ins, org, token, out, err] = setupComponent()

  err.once 'data', (data) ->
    test.ok data, 'Errors are objects'
    test.ok data.message, 'There needs to be an error message'
    test.equal data.message, 'organization name required'

    test.done()

  ins.send 'xyz123456'

exports['test creating without token'] = (test) ->
  [c, ins, org, token, out, err] = setupComponent()

  err.once 'data', (data) ->
    test.ok data, 'Errors are objects'
    test.ok data.message, 'There needs to be an error message'
    test.equal data.message, 'token required'

    test.done()

  org.send 'foo'
  ins.send 'xyz123456'
