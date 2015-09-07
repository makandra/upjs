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

  lastScrollTops = u.cache(size: 30)

  ###*
  @method up.history.defaults
  @param [options.popTarget=`'body'`]
    Which container to replace when the user goes
    back in history.
  @param [options.restoreScroll=`true`]
    Whether to restore the known scroll positions
    when the user goes back in history.
  ###
  config = u.config
    popTarget: 'body'
    restoreScroll: true

  reset = ->
    config.reset()
    lastScrollTops.clear()
  
  isCurrentUrl = (url) ->
    u.normalizeUrl(url, hash: true) == u.normalizeUrl(up.browser.url(), hash: true)
    
  ###*
  @method up.history.replace
  @param {String} url
  @param {Boolean} [options.force=false]
  @protected
  ###
  replace = (url, options) ->
    options = u.options(options, force: false)
    if options.force || !isCurrentUrl(url)
      manipulate("replace", url)

  ###*
  @method up.history.push  
  @param {String} url
  @protected
  ###
  push = (url) ->
    manipulate("push", url) unless isCurrentUrl(url)

  ###*
  @private
  ###
  manipulate = (method, url) ->
    if up.browser.canPushState()
      method += "State" # resulting in either pushState or replaceState
      state = buildState()
      lastScrollTops.set(u.normalizeUrl(url), state.scrollTops)
      window.history[method](state, '', url)
    else
      u.error "This browser doesn't support history.pushState"

  ###*
  Restores the top scroll positions of all the
  viewports configured in `up.layout.defaults('viewports')`.

  @method up.history.restoreScroll()
  @protected
  ###
  restoreScroll = (options = {}) ->
    # If we aren't given a hash of selector => scrollTop,
    # try to find the last scroll positions that we saved for
    # the current URL
    unless options.tops
      url = u.normalizeUrl(up.browser.url())
      options.tops = lastScrollTops.get(url, {})

    $viewports = if options.within
      up.layout.viewportsIn(options.within)
    else
      up.layout.viewports()

    for selector, scrollTop of options.tops
      $matchingViewport = $viewports.filter(selector)
      up.scroll($matchingViewport, scrollTop, duration: 0)

  buildState = ->
    fromUp: true
    scrollTops: up.layout.scrollTops()

  restoreStateOnPop = (state) ->
    url = up.browser.url()
    u.debug "Restoring state %o (now on #{url})", state
    up.replace(config.popTarget, url, historyMethod: 'replace').then ->
      restoreScroll(tops: state.scrollTops) if config.restoreScroll

  pop = (event) ->
    state = event.originalEvent.state
    if state?.fromUp
      restoreStateOnPop(state)
    else
      u.debug 'Discarding unknown state %o', state

  if up.browser.canPushState()
    register = ->
      $(window).on "popstate", pop
      replace(up.browser.url(), force: true)

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
  restoreScroll: restoreScroll

)()
