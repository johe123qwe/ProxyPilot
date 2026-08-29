module.exports =
  index:
    files:
      'index.js': 'index.coffee'
    options:
      # The jsondiffpatch patch has to be global: plain transforms are not
      # applied to files inside node_modules.
      transform: [
        'coffeeify'
        ['./browserify_jsondiffpatch_env.js', {global: true}]
      ]
      exclude: ['bluebird', 'jsondiffpatch', 'omega-pac']
      browserifyOptions:
        extensions: '.coffee'
        builtins: []
        standalone: 'index.coffee'
        debug: true
  browser:
    files:
      'omega_target.min.js': 'index.coffee'
    options:
      alias: [
        './index.coffee:OmegaTarget'
      ]
      # The jsondiffpatch patch has to be global: plain transforms are not
      # applied to files inside node_modules.
      transform: [
        'coffeeify'
        ['./browserify_jsondiffpatch_env.js', {global: true}]
      ]
      plugin:
        if process.env.BUILD == 'release'
          [['minifyify', {map: false}]]
        else
          []
      browserifyOptions:
        extensions: '.coffee'
        standalone: 'OmegaTarget'
