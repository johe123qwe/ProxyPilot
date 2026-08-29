angular.module('omega').controller 'BuiltinCtrl', ($scope, $rootScope,
  builtinProfiles) ->
  $scope.builtinProfileList =
    for own key, profile of builtinProfiles
      {key: key, name: profile.name, color: profile.color}

  $scope.setColor = (entry, color) ->
    entry.color = color
    overrides = angular.copy($rootScope.options['-builtinProfiles'] ? {})
    overrides[entry.key] = {color: color}
    # Replace the whole object so the options watcher sees a new value and
    # marks the options dirty; mutating in place would not be picked up.
    $rootScope.options['-builtinProfiles'] = overrides
