component = require "../components/GetRepository"
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

exports['test reading a valid repository'] = (test) ->
  [c, ins, token, out, err] = setupComponent()

  out.once 'data', (data) ->
    test.ok data, "We need to get a repository object"
    test.ok data.full_name, "We need to get the repository name"
    test.equal data.full_name, 'bergie/create'

    test.done()

  ins.send 'bergie/create'

exports['test reading a non-existing repository'] = (test) ->
  [c, ins, token, out, err] = setupComponent()

  err.once 'data', (data) ->
    test.ok data, 'Errors are objects'
    test.ok data.message, 'There needs to be an error message'
    test.equal data.message, 'Not Found'

    test.done()

  ins.send 'bergie/xyz123456'
