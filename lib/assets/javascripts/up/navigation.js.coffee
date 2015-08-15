###*
Fast interaction feedback
=========================
  
This module marks up link elements with classes indicating that
they are currently loading (class `up-active`) or linking
to the current location (class `up-current`).

This dramatically improves the perceived speed of your user interface
by providing instant feedback for user interactions.

@class up.navigation
###
up.navigation = (->

  u = up.util

  ###*
  Sets default options for this module.

  @param {Number} [options.currentClass]
    The class to set on [links that point the current location](#up-current).
  @method up.navigation.defaults
  ###
  config = u.config
    currentClass: 'up-current'

  currentClass = ->
    klass = config.currentClass
    unless u.contains(klass, 'up-current')
      klass += ' up-current'
    klass

  CLASS_ACTIVE = 'up-active'
  SELECTORS_SECTION = ['a', '[up-href]', '[up-alias]']
  SELECTOR_SECTION = SELECTORS_SECTION.join(', ')
  SELECTOR_SECTION_INSTANT = ("#{selector}[up-instant]" for selector in SELECTORS_SECTION).join(', ')
  SELECTOR_ACTIVE = ".#{CLASS_ACTIVE}"
  
  normalizeUrl = (url) ->
    if u.isPresent(url)
      u.normalizeUrl(url,
        search: false
        stripTrailingSlash: true
      )
    
  sectionUrls = ($section) ->
    urls = []
    for attr in ['href', 'up-href']
      if value = u.presentAttr($section, attr)
        urls.push(value)
    if aliases = u.presentAttr($section, 'up-alias')
      values = aliases.split(' ')
      urls = urls.concat(values)
    urls.map normalizeUrl

  urlSet = (urls) ->
    urls = u.compact(urls)

    matches = (testUrl) ->
      if testUrl.substr(-1) == '*'
        doesMatchPrefix(testUrl.slice(0, -1))
      else
        doesMatchFully(testUrl)

    doesMatchFully = (testUrl) ->
      u.contains(urls, testUrl)

    doesMatchPrefix = (prefix) ->
      u.detect urls, (url) ->
        url.indexOf(prefix) == 0

    matchesAny = (testUrls) ->
      u.detect(testUrls, matches)

    matchesAny: matchesAny

  locationChanged = ->
    currentUrls = urlSet([
      normalizeUrl(up.browser.url()),
      normalizeUrl(up.modal.source()),
      normalizeUrl(up.popup.source())
    ])

    klass = currentClass()

    u.each $(SELECTOR_SECTION), (section) ->
      $section = $(section)
      # if $section is marked up with up-follow,
      # the actual link might be a child element.
      urls = sectionUrls($section)

      if currentUrls.matchesAny(urls)
        $section.addClass(klass)
      else
        $section.removeClass(klass)

  ###*
  Links that are currently loading are assigned the `up-active`
  class automatically. Style `.up-active` in your CSS to improve the
  perceived responsiveness of your user interface.

  The `up-active` class will be removed as soon as another
  page fragment is added or updated through Up.js.

  \#\#\#\# Example

  We have a link:

      <a href="/foo" up-follow>Foo</a>

  The user clicks on the link. While the request is loading,
  the link has the `up-active` class:

      <a href="/foo" up-follow up-active>Foo</a>

  Once the fragment is loaded the browser's location bar is updated
  to `http://yourhost/foo` via [`history.pushState`](https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Manipulating_the_browser_history#Adding_and_modifying_history_entries):

      <a href="/foo" up-follow up-current>Foo</a>

  @ujs
  @method [up-active]
  ###
  sectionClicked = ($section) ->
    unmarkActive()
    $section = enlargeClickArea($section)
    $section.addClass(CLASS_ACTIVE)
    
  enlargeClickArea = ($section) ->
    u.presence($section.parents(SELECTOR_SECTION)) || $section
    
  unmarkActive = ->
    $(SELECTOR_ACTIVE).removeClass(CLASS_ACTIVE)

  up.on 'click', SELECTOR_SECTION, (event, $section) ->
    if u.isUnmodifiedMouseEvent(event) && !$section.is('[up-instant]')
      sectionClicked($section)
  
  up.on 'mousedown', SELECTOR_SECTION_INSTANT, (event, $section) ->
    if u.isUnmodifiedMouseEvent(event)
      sectionClicked($section)

  ###*
  Links that point to the current location are assigned
  the `up-current` class automatically.

  The use case for this is navigation bars:

      <nav>
        <a href="/foo">Foo</a>
        <a href="/bar">Bar</a>
      </nav>

  If the browser location changes to `/foo`, the markup changes to this:

      <nav>
        <a href="/foo" up-current>Foo</a>
        <a href="/bar">Bar</a>
      </nav>

  \#\#\#\# What's considered to be "current"?

  The current location is considered to be either:

  - the URL displayed in the browser window's location bar
  - the source URL of a currently opened [modal dialog](/up.modal)
  - the source URL of a currently opened [popup overlay](/up.popup)

  A link matches the current location (and is marked as `.up-current`) if it matches either:

  - the link's `href` attribute
  - the link's [`up-href`](/up.link#turn-any-element-into-a-link) attribute
  - a space-separated list of URLs in the link's `up-alias` attribute

  \#\#\#\# Matching URL by prefix

  You can mark a link as `.up-current` whenever the current URL matches a prefix.
  To do so, end the `up-alias` attribute in an asterisk (`*`).

  For instance, the following link is highlighted for both `/reports` and `/reports/123`:

      <a href="/reports" up-alias="/reports/*">Reports</a>

  @method [up-current]
  @ujs
  ###
  up.bus.on 'fragment:ready', ->
    # If a new fragment is inserted, it's likely to be the result
    # of the active action. So we can remove the active marker.
    unmarkActive()
    # When a fragment is ready it might either have brought a location change
    # with it, or it might have opened a modal / popup which we consider
    # to be secondary location sources (the primary being the browser's
    # location bar).
    locationChanged()

  up.bus.on 'fragment:destroy', ($fragment) ->
    # If the destroyed fragment is a modal or popup container
    # this changes which URLs we consider currents.
    # Also modals and popups restore their previous history
    # once they close.
    if $fragment.is('.up-modal, .up-popup')
      locationChanged()

  defaults: config.update

)()
