noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-github'

describe 'GetStargazers component', ->
  c = null
  repo = null
  token = null
  out = null
  files = null
  err = null
  before (done) ->
    return @skip() unless process?.env?.GITHUB_API_TOKEN
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'github/GetStargazers', (err, instance) ->
      return done err if err
      c = instance
      repo = noflo.internalSocket.createSocket()
      c.inPorts.repository.attach repo
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

  describe 'reading from a valid repo', ->
    before ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
    it 'should produce a list of stargazers', (done) ->
      @timeout 20000
      received = 0
      err.on 'data', done

      groups = []
      out.on 'begingroup', (group) ->
        groups.push group
      out.on 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.login).to.be.a 'string'
        chai.expect(groups).to.eql ['noflo/noflo-ui']
        received++
      out.on 'endgroup', ->
        groups.pop()
      out.on 'disconnect', ->
        chai.expect(received).to.be.above 100
        chai.expect(groups).to.eql []
        done()

      token.send process.env.GITHUB_API_TOKEN
      repo.send 'noflo/noflo-ui'
      repo.disconnect()
