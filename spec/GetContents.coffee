noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-github'

describe 'GetContents component', ->
  c = null
  repo = null
  path = null
  token = null
  out = null
  files = null
  err = null
  before (done) ->
    return @skip() unless process?.env?.GITHUB_API_TOKEN
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'github/GetContents', (err, instance) ->
      return done err if err
      c = instance
      path = noflo.internalSocket.createSocket()
      c.inPorts.path.attach path
      repo = noflo.internalSocket.createSocket()
      c.inPorts.repository.attach repo
      token = noflo.internalSocket.createSocket()
      c.inPorts.token.attach token
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
    files = noflo.internalSocket.createSocket()
    c.outPorts.files.attach files
    err = noflo.internalSocket.createSocket()
    c.outPorts.error.attach err
  afterEach ->
    c.outPorts.out.detach out
    out = null
    c.outPorts.files.detach files
    files = null
    c.outPorts.error.detach err
    err = null

  describe 'reading a valid JSON file', ->
    before ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
    it 'should produce parseable contents', (done) ->
      err.on 'data', done

      out.on 'data', (data) ->
        chai.expect(data).to.be.a 'string'
        try
          packageData = JSON.parse data
        catch e
          return done e
        chai.expect(packageData.name).to.equal '@bergie/create'
        done()

      token.send process.env.GITHUB_API_TOKEN
      repo.send 'bergie/create'
      path.send 'package.json'

  describe 'reading a valid directory', ->
    before ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
    it 'should produce a listing of files', (done) ->
      err.on 'data', done

      found = 0
      files.on 'data', (data) ->
        chai.expect(data.path).to.contain 'locale/'
        found++
      files.on 'disconnect', ->
        chai.expect(found).to.be.above 2
        done()

      token.send process.env.GITHUB_API_TOKEN
      repo.send 'bergie/create'
      path.send 'locale'

  describe 'reading a missing file', (done) ->
    before ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
    it 'should produce an error', (done) ->
      @timeout 4000
      out.on 'data', (data) ->
        return done new Error 'Unexpected data received'
      err.on 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.be.a 'string'
        chai.expect(data.code).to.equal 404
        done()

      token.send process.env.GITHUB_API_TOKEN
      repo.send 'bergie/create'
      path.send 'xyz123456.json'
