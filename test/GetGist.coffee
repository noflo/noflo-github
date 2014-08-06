component = require "../components/GetGist"
socket = require('noflo').internalSocket

setupComponent = ->
  c = component.getComponent()
  id = socket.createSocket()
  token = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.gist.attach id
  c.inPorts.token.attach token
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  [c, id, token, out, err]

exports['test reading a valid gist with token'] = (test) ->
  [c, id, token, out, err] = setupComponent()

  out.once 'data', (data) ->
    test.ok data, "We need to get the gist contents"
    test.ok data.files['noflo.json'], 'There should be the expected graph file inside'
    test.done()
  err.once 'data', (data) ->
    test.ok false, 'We should have gotten a result'
    test.done()

  token.send process.env.GITHUB_API_TOKEN
  id.send '1d42f66f5cc4614df935'

exports['test reading a valid gist without token'] = (test) ->
  [c, id, token, out, err] = setupComponent()

  out.once 'data', (data) ->
    test.ok data, "We need to get the gist contents"
    test.ok data.files['noflo.json'], 'There should be the expected graph file inside'
    test.done()
  err.once 'data', (data) ->
    test.ok false, 'We should have gotten a result'
    test.done()

  id.send '1d42f66f5cc4614df935'
