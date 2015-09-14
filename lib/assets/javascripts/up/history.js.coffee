###*
Manipulating the browser history
=======
  
\#\#\# Incomplete documentation!
  
We need to work on this page:

- Explain how the other modules manipulate history
- Decide whether we want to expose these methods as public API
- Document methods and parameters

@class up.history
###
up.history = (->
  
  u = up.util

  ###*
  @method up.history.defaults
  @param {Array<String>} [options.popTarget=`'body'`]
    An array of CSS selectors to replace when the user goes
    back in history.
  @param {Boolean} [options.restoreScroll=`true`]
    Whether to restore the known scroll positions
    when the user goes back or forward in history.
  ###
  config = u.config
    popTargets: ['body']
    restoreScroll: true

  previousUrl = undefined
  nextPreviousUrl = undefined

  reset = ->
    config.reset()
    previousUrl = undefined
    nextPreviousUrl = undefined

  normalizeUrl = (url) ->
    u.normalizeUrl(url, hash: true)

  ###*
  Returns a normalized URL for the current history entry.

  @method up.history.url
  @protected
  ####
  currentUrl = ->
    normalizeUrl(up.browser.url())
  
  isCurrentUrl = (url) ->
    normalizeUrl(url) == currentUrl()

  observeNewUrl = (url) ->
    if nextPreviousUrl
      previousUrl = nextPreviousUrl
      nextPreviousUrl = undefined
    nextPreviousUrl = url

  ###*
  @method up.history.replace
  @param {String} url
  @param {Boolean} [options.force=false]
  @protected
  ###
  replace = (url, options) ->
    manipulate("replace", url, options)

  ###*
  @method up.history.push  
  @param {String} url
  @protected
  ###
  push = (url, options) ->
    manipulate("push", url, options)

  manipulate = (method, url, options) ->
    options = u.options(options, force: false)
    if options.force || !isCurrentUrl(url)
      if up.browser.canPushState()
        method += "State" # resulting in either pushState or replaceState
        state = buildState()
        console.log("[#{method}] URL %o with state %o", url, state)
        previousUrl = url
        window.history[method](state, '', url)
      else
        u.error "This browser doesn't support history.pushState"

  buildState = ->
    fromUp: true

  restoreStateOnPop = (state) ->
    url = currentUrl()
    u.debug "Restoring state %o (now on #{url})", state
    popSelector = config.popTargets.join(', ')
    up.replace popSelector, url,
      history: false,
      reveal: false,
      transition: 'none',
      saveScroll: false
      restoreScroll: config.restoreScroll

  pop = (event) ->
    console.log("[pop] pop to url %o", currentUrl())
    observeNewUrl(currentUrl())
    up.layout.saveScroll(url: previousUrl)
    state = event.originalEvent.state
    if state?.fromUp
      restoreStateOnPop(state)
    else
      u.debug 'Discarding unknown state %o', state

  if up.browser.canPushState()
    register = ->
      $(window).on "popstate", pop
      replace(currentUrl(), force: true)

    if jasmine?
      # Can't delay this in tests.
      register()
    else
      # Defeat an unnecessary popstate that some browsers trigger
      # on pageload (Safari, Chrome < 34).
      # We should check in 2023 if we can remove this.
      setTimeout register, 100

  up.bus.on 'framework:reset', reset

  defaults: config.update
  push: push
  replace: replace
  url: currentUrl
  normalizeUrl: normalizeUrl

)()
