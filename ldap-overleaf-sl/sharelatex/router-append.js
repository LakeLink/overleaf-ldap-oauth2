  webRouter.get('/oauth/redirect', AuthenticationController.oauth2Redirect)
  webRouter.get('/oauth/callback', AuthenticationController.oauth2Callback)
  AuthenticationController.addEndpointToLoginWhitelist('/oauth/redirect')
  AuthenticationController.addEndpointToLoginWhitelist('/oauth/callback')
  webRouter.get('*', ErrorController.notFound)
}
