component = require "../components/GetContents"
socket = require('noflo').internalSocket

setupComponent = ->
  c = component.getComponent()
  repo = socket.createSocket()
  path = socket.createSocket()
  token = socket.createSocket()
  out = socket.createSocket()
  files = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.repository.attach repo
  c.inPorts.path.attach path
  c.inPorts.token.attach token
  c.outPorts.out.attach out
  c.outPorts.files.attach files
  c.outPorts.error.attach err
  [c, repo, path, token, out, err, files]

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
  err.once 'data', (data) ->
    test.ok false, 'We should have gotten a result'
    test.done()

  token.send process.env.GITHUB_API_TOKEN
  repo.send 'bergie/create'
  path.send 'package.json'

exports['test reading a valid directory'] = (test) ->
  [c, repo, path, token, out, err, files] = setupComponent()

  found = 0
  files.on 'data', (data) ->
    test.ok data.path.indexOf('locale/') isnt -1
    found++
  files.on 'disconnect', ->
    test.ok found > 2
    test.done()
  err.once 'data', (data) ->
    test.ok false, 'We should have gotten a result'
    test.done()

  token.send process.env.GITHUB_API_TOKEN
  repo.send 'bergie/create'
  path.send 'locale'

exports['test reading a non-existing repository'] = (test) ->
  [c, repo, path, token, out, err] = setupComponent()

  err.once 'data', (data) ->
    test.ok data, 'Errors are objects'
    test.ok data.message, 'There needs to be an error message'
    test.equal data.message, 'Not Found'

    test.done()

  token.send process.env.GITHUB_API_TOKEN
  repo.send 'bergie/xyz123456'
  path.send 'package.json'

exports['test reading a non-existing file'] = (test) ->
  [c, repo, path, token, out, err] = setupComponent()

  err.once 'data', (data) ->
    test.ok data, 'Errors are objects'
    test.ok data.message, 'There needs to be an error message'
    test.equal data.message, 'Not Found'

    test.done()

  token.send process.env.GITHUB_API_TOKEN
  repo.send 'bergie/create'
  path.send 'xyz123456.json'
