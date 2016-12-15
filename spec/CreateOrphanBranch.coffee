noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-github'

describe 'CreateOrphanBranch component', ->
  c = null
  branch = null
  repo = null
  token = null
  out = null
  err = null
  before (done) ->
    return @skip() unless process?.env?.GITHUB_API_TOKEN
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'github/CreateOrphanBranch', (err, instance) ->
      return done err if err
      c = instance
      branch = noflo.internalSocket.createSocket()
      c.inPorts.branch.attach branch
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

  describe 'creating a missing branch', ->
    before ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
    it 'should succeed', (done) ->
      @timeout 10000
      testBranch = "branch_#{Date.now()}"

      err.on 'data', done
      out.on 'data', (data) ->
        chai.expect(data).to.equal testBranch
        done()

      token.send process.env.GITHUB_API_TOKEN
      repo.send 'the-domains/example.net'
      branch.send testBranch

  describe 'creating an existing branch', ->
    before ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
    it 'should succeed', (done) ->
      @timeout 10000
      err.on 'data', done
      out.on 'data', (data) ->
        chai.expect(data).to.equal 'master'
        done()

      token.send process.env.GITHUB_API_TOKEN
      repo.send 'the-domains/example.net'
      branch.send 'master'

  describe 'creating a branch to a newly-initialized repo', ->
    api = null
    before (done) ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
      @timeout 4000
      api = c.getOcto().api()
      api.token process.env.GITHUB_API_TOKEN
      request = api.post "/orgs/the-domains/repos",
        name: "example.com"
        private: false
        has_issues: false
        has_wiki: false
        has_downloads: false
        auto_init: true
      request.on 'success', (res) ->
        setTimeout ->
          done()
        , 1000
      request.on 'error', (err) ->
        done new Error err.body.message
      do request
      return
    after (done) ->
      return @skip() unless process?.env?.GITHUB_API_TOKEN
      @timeout 4000
      request = api.del "/repos/the-domains/example.com"
      request.on 'success', ->
        done()
      request.on 'error', (err) ->
        done new Error err.body.message
      do request
      api = null
      return
    it 'should succeed', (done) ->
      @timeout 10000
      err.on 'data', done
      out.on 'data', (data) ->
        chai.expect(data).to.equal 'grid-pages'
        done()
      token.send process.env.GITHUB_API_TOKEN
      repo.send 'the-domains/example.com'
      branch.send 'grid-pages'
