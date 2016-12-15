noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-github'

describe 'GetRepository component', ->
  c = null
  ins = null
  token = null
  out = null
  err = null
  before (done) ->
    return @skip() unless process?.env?.GITHUB_API_TOKEN
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'github/GetRepository', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
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

  describe 'reading a valid repository', ->
    before ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
    it 'should succeed', (done) ->
      err.on 'data', done
      out.on 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.full_name).to.equal 'bergie/create'
        done()

      token.send process.env.GITHUB_API_TOKEN
      ins.send 'bergie/create'

  describe 'reading a missing repository', ->
    before ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
    @timeout 6000
    it 'should fail', (done) ->
      out.on 'data', (data) ->
        return done new Error 'Should not have returned data'
      err.on 'data', (data) ->
        chai.expect(data).to.be.an 'error'
        chai.expect(data.status).to.equal 404
        done()

      token.send process.env.GITHUB_API_TOKEN
      ins.send 'bergie/xyz123456'
