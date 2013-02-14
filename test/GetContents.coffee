component = require "../components/GetContents"
socket = require('noflo').internalSocket

setupComponent = ->
  c = component.getComponent()
  repo = socket.createSocket()
  path = socket.createSocket()
  token = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.repository.attach repo
  c.inPorts.path.attach path
  c.inPorts.token.attach token
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  [c, repo, path, token, out, err]

exports['test reading a valid file'] = (test) ->
  [c, repo, path, token, out, err] = setupComponent()

  out.once 'data', (data) ->
    test.ok data, "We need to get the file contents"
    try
      packagedata = JSON.parse data
    catch e
      test ok false, "JSON parsing failed"
      return test.done()
    test.ok packagedata.name
    test.equal packagedata.name, 'create'

    test.done()

  repo.send 'bergie/create'
  path.send 'package.json'

exports['test reading a non-existing repository'] = (test) ->
  [c, repo, path, token, out, err] = setupComponent()

  err.once 'data', (data) ->
    test.ok data, 'Errors are objects'
    test.ok data.message, 'There needs to be an error message'
    test.equal data.message, 'Not Found'

    test.done()

  repo.send 'bergie/xyz123456'
  path.send 'package.json'

exports['test reading a non-existing file'] = (test) ->
  [c, repo, path, token, out, err] = setupComponent()

  err.once 'data', (data) ->
    test.ok data, 'Errors are objects'
    test.ok data.message, 'There needs to be an error message'
    test.equal data.message, 'Not Found'

    test.done()

  repo.send 'bergie/create'
  path.send 'xyz123456.json'
