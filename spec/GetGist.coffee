noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-github'

describe 'GetGist component', ->
  c = null
  id = null
  token = null
  out = null
  err = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'github/GetGist', (err, instance) ->
      return done err if err
      c = instance
      id = noflo.internalSocket.createSocket()
      c.inPorts.gist.attach id
      token = noflo.internalSocket.createSocket()
      c.inPorts.token.attach token
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
    err = noflo.internalSocket.createSocket()
    c.outPorts.error.attach err
  afterEach ->
    c.outPorts.out.detach out
    out = null
    c.outPorts.error.detach err
    err = null

  describe 'reading a valid gist without token', ->
    it 'should succeed', (done) ->
      err.on 'data', done
      out.on 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.files['noflo.json']).to.be.a 'object'
        done()
      id.send '1d42f66f5cc4614df935'
  describe 'reading a valid gist with token', ->
    before ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
    it 'should succeed', (done) ->
      err.on 'data', done
      out.on 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.files['noflo.json']).to.be.a 'object'
        done()
      token.send process.env.GITHUB_API_TOKEN
      id.send '1d42f66f5cc4614df935'
