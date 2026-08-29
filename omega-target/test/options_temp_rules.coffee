chai = require 'chai'
should = chai.should()

describe 'Options temp rules', ->
  Options = require '../src/options'
  Storage = require '../src/storage'
  Log = require '../src/log'

  noop = -> return
  quietLog = Object.create(Log)
  quietLog.log = noop
  quietLog.error = noop
  quietLog.method = noop

  testOptions = ->
    schemaVersion: 2
    '-startupProfileName': ''
    '+auto switch':
      name: 'auto switch'
      profileType: 'SwitchProfile'
      color: '#99dd99'
      defaultProfileName: 'direct'
      rules: []
    '+proxy':
      name: 'proxy'
      profileType: 'FixedProfile'
      color: '#99ccee'
      bypassList: []
      fallbackProxy: {scheme: 'http', host: '127.0.0.1', port: 8080}

  Promise = require 'bluebird'
  proxyImpl =
    applyProfile: -> Promise.resolve()
    watchProxyChange: noop
    features: []

  newOptions = ->
    options = new Options(testOptions(), new Storage(), new Storage(),
      quietLog, null, proxyImpl)
    options.ready.then -> options

  applySwitch = (options) ->
    options.applyProfile('auto switch').return(options)

  it 'should report no temp rules initially', ->
    newOptions().then (options) ->
      options.getTempRules().should.deep.equal([])

  it 'should list added temp rules sorted by domain', ->
    newOptions().then(applySwitch).then (options) ->
      options.addTempRule('example.com', 'proxy').then ->
        options.addTempRule('a.example.org', 'direct').then ->
          options.getTempRules().should.deep.equal([
            {domain: 'a.example.org', profileName: 'direct'}
            {domain: 'example.com', profileName: 'proxy'}
          ])

  it 'should remove a single temp rule', ->
    newOptions().then(applySwitch).then (options) ->
      options.addTempRule('example.com', 'proxy').then ->
        options.addTempRule('example.org', 'direct').then ->
          options.removeTempRule('example.com').then ->
            options.getTempRules().should.deep.equal([
              {domain: 'example.org', profileName: 'direct'}
            ])
            should.not.exist(options.queryTempRule('example.com'))

  it 'should drop the removed rule from the temp profile', ->
    newOptions().then(applySwitch).then (options) ->
      options.addTempRule('example.com', 'proxy').then ->
        options._tempProfile.rules.length.should.equal(1)
        options.removeTempRule('example.com').then ->
          options._tempProfile.rules.length.should.equal(0)

  it 'should ignore removing a rule that does not exist', ->
    newOptions().then(applySwitch).then (options) ->
      options.removeTempRule('nosuch.example').then ->
        options.getTempRules().should.deep.equal([])

  it 'should clear every temp rule', ->
    newOptions().then(applySwitch).then (options) ->
      options.addTempRule('example.com', 'proxy').then ->
        options.addTempRule('example.org', 'direct').then ->
          options.clearTempRules().then ->
            options.getTempRules().should.deep.equal([])
            options._tempProfile.rules.length.should.equal(0)

  it 'should reflect a changed profile for an existing domain', ->
    newOptions().then(applySwitch).then (options) ->
      options.addTempRule('example.com', 'proxy').then ->
        options.addTempRule('example.com', 'direct').then ->
          options.getTempRules().should.deep.equal([
            {domain: 'example.com', profileName: 'direct'}
          ])
