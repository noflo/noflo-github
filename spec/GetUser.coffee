noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-github'

describe 'GetUser component', ->
  c = null
  id = null
  token = null
  out = null
  err = null
  before (done) ->
    return @skip() unless process?.env?.GITHUB_API_TOKEN
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'github/GetUser', (err, instance) ->
      return done err if err
      c = instance
      id = noflo.internalSocket.createSocket()
      c.inPorts.user.attach id
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

  describe 'reading a valid user', ->
    before ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
    it 'should send user data', (done) ->
      err.on 'data', done
      out.on 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.login).to.be.a 'string'
        chai.expect(data.name).to.be.a 'string'
        done()

      token.send process.env.GITHUB_API_TOKEN
      id.send 'bergie'
