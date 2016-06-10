noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-github'

describe 'CreateOrgRepository component', ->
  c = null
  ins = null
  org = null
  token = null
  out = null
  err = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'github/CreateOrgRepository', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
      org = noflo.internalSocket.createSocket()
      c.inPorts.org.attach org
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

  describe 'trying to create a repository without a token', ->
    it 'should produce an error', (done) ->
      err.on 'data', (data) ->
        chai.expect(data).to.be.an 'error'
        chai.expect(data.message).to.equal 'token required'
        done()

      token.send null
      org.send 'foo'
      ins.send 'xyz123456'
