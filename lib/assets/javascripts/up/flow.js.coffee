###*
Changing page fragments programmatically
========================================
  
This module contains Up.js's core functions to [change](/up.replace) or [destroy](/up.destroy)
  page fragments via Javascript.

All the other Up.js modules (like [`up.link`](/up.link) or [`up.modal`](/up.modal))
are based on this module.
  
@class up.flow
###
up.flow = (($) ->
  
  u = up.util

  setSource = (element, sourceUrl) ->
    $element = $(element)
    sourceUrl = u.normalizeUrl(sourceUrl) if u.isPresent(sourceUrl)
    $element.attr("up-source", sourceUrl)

  ###*
  Returns the URL the given element was retrieved from.

  @method up.flow.source
  @param {String|Element|jQuery} selectorOrElement
  @experimental
  ###
  source = (selectorOrElement) ->
    $element = $(selectorOrElement).closest('[up-source]')
    u.presence($element.attr("up-source")) || up.browser.url()

  ###*
  Resolves the given selector (which might contain `&` references)
  to an absolute selector.

  @function up.flow.resolveSelector
  @param {String|Element|jQuery} selectorOrElement
  @param {String|Element|jQuery} origin
    The element that this selector resolution is relative to.
    That element's selector will be substituted for `&`.
  @internal
  ###
  resolveSelector = (selectorOrElement, origin) ->
    if u.isString(selectorOrElement)
      selector = selectorOrElement
      if u.contains(selector, '&')
        if origin
          originSelector = u.selectorForElement(origin)
          selector = selector.replace(/\&/, originSelector)
        else
          u.error("Found origin reference (%s) in selector %s, but options.origin is missing", '&', selector)
    else
      selector = u.selectorForElement(selectorOrElement)
    selector

  ###*
  Replaces elements on the current page with corresponding elements
  from a new page fetched from the server.

  The current and new elements must have the same CSS selector.

  \#\#\#\# Example

  Let's say your curent HTML looks like this:

      <div class="one">old one</div>
      <div class="two">old two</div>

  We now replace the second `<div>`:

      up.replace('.two', '/new');

  The server renders a response for `/new`:

      <div class="one">new one</div>
      <div class="two">new two</div>

  Up.js looks for the selector `.two` in the response and [implants](/up.extract) it into
  the current page. The current page now looks like this:

      <div class="one">old one</div>
      <div class="two">new two</div>

  Note how only `.two` has changed. The update for `.one` was
  discarded, since it didn't match the selector.

  \#\#\#\# Appending or prepending instead of replacing

  By default Up.js will replace the given selector with the same
  selector from a freshly fetched page. Instead of replacing you
  can *append* the loaded content to the existing content by using the
  `:after` pseudo selector. In the same fashion, you can use `:before`
  to indicate that you would like the *prepend* the loaded content.

  A practical example would be a paginated list of items:

      <ul class="tasks">
        <li>Wash car</li>
        <li>Purchase supplies</li>
        <li>Fix tent</li>
      </ul>

  In order to append more items from a URL, replace into
  the `.tasks:after` selector:

      up.replace('.tasks:after', '/page/2')

  \#\#\#\# Setting the window title from the server

  If the `replace` call changes history, the document title will be set
  to the contents of a `<title>` tag in the response.

  The server can also change the document title by setting
  an `X-Up-Title` header in the response.

  \#\#\#\# Optimizing response rendering

  The server is free to optimize Up.js requests by only rendering the HTML fragment
  that is being updated. The request's `X-Up-Target` header will contain
  the CSS selector for the updating fragment.

  If you are using the `upjs-rails` gem you can also access the selector via
  `up.selector` in all controllers, views and helpers.

  \#\#\#\# Events

  Up.js will emit [`up:fragment:destroyed`](/up:fragment:destroyed) on the element
  that was replaced and [`up:fragment:inserted`](/up:fragment:inserted) on the new
  element that replaces it.

  @function up.replace
  @param {String|Element|jQuery} selectorOrElement
    The CSS selector to update. You can also pass a DOM element or jQuery element
    here, in which case a selector will be inferred from the element's class and ID.
  @param {String} url
    The URL to fetch from the server.
  @param {String} [options.failTarget='body']
    The CSS selector to update if the server sends a non-200 status code.
  @param {String} [options.title]
  @param {String} [options.method='get']
  @param {Object|Array} [options.data]
    Parameters that should be sent as the request's payload.

    Parameters can either be passed as an object (where the property names become
    the param names and the property values become the param values) or as
    an array of `{ name: 'param-name', value: 'param-value' }` objects
    (compare to jQuery's [`serializeArray`](https://api.jquery.com/serializeArray/)).
  @param {String} [options.transition='none']
  @param {String|Boolean} [options.history=true]
    If a `String` is given, it is used as the URL the browser's location bar and history.
    If omitted or true, the `url` argument will be used.
    If set to `false`, the history will remain unchanged.
  @param {String|Boolean} [options.source=true]
  @param {String} [options.reveal=false]
    Whether to [reveal](/up.reveal) the element being updated, by
    scrolling its containing viewport.
  @param {Boolean} [options.restoreScroll=false]
    If set to true, Up.js will try to restore the scroll position
    of all the viewports around or below the updated element. The position
    will be reset to the last known top position before a previous
    history change for the current URL.
  @param {Boolean} [options.cache]
    Whether to use a [cached response](/up.proxy) if available.
  @param {Element|jQuery} [options.origin]
    The element that triggered the replacement. The element's selector will
    be substituted for the `&` shorthand in the target selector.
  @param {String} [options.historyMethod='push']
  @param {Object} [options.headers={}]
    An object of additional header key/value pairs to send along
    with the request.
  @param {Boolean} [options.requireMatch=true]
    Whether to raise an error if the given selector is missing in
    either the current page or in the response.
  @return {Promise}
    A promise that will be resolved when the page has been updated.
  @stable
  ###
  replace = (selectorOrElement, url, options) ->
    up.puts "Replacing %s from %s (%o)", selectorOrElement, url, options
    options = u.options(options)
    target = resolveSelector(selectorOrElement, options.origin)
    failTarget = u.option(options.failTarget, 'body')
    failTarget = resolveSelector(failTarget, options.origin)

    if !up.browser.canPushState() && options.history != false
      unless options.preload
        up.browser.loadPage(url, u.only(options, 'method', 'data'))
      return u.unresolvablePromise()

    request =
      url: url
      method: options.method
      data: options.data
      target: target
      failTarget: failTarget
      cache: options.cache
      preload: options.preload
      headers: options.headers

    promise = up.ajax(request)

    promise.done (html, textStatus, xhr) ->
      processResponse(true, target, url, request, xhr, options)

    promise.fail (xhr, textStatus, errorThrown) ->
      processResponse(false, failTarget, url, request, xhr, options)
    promise

  ###*
  @internal
  ###
  processResponse = (isSuccess, selector, url, request, xhr, options) ->
    options.method = u.normalizeMethod(u.option(u.methodFromXhr(xhr), options.method))
    options.title = u.option(u.titleFromXhr(xhr), options.title)
    isReloadable = (options.method == 'GET')

    # The server can send us the current path using a header value.
    # This way we know the actual URL if the server has redirected.
    if urlFromServer = u.locationFromXhr(xhr)
      url = urlFromServer
      if isSuccess
        newRequest =
          url: url
          method: u.methodFromXhr(xhr)
          target: selector
        up.proxy.alias(request, newRequest)
    else if isReloadable
      if query = u.requestDataAsQuery(options.data)
        url = "#{url}?#{query}"

    if isSuccess
      if isReloadable # e.g. GET returns 200 OK
        options.history = url unless options.history is false || u.isString(options.history)
        options.source  = url unless options.source  is false || u.isString(options.source)
      else # e.g. POST returns 200 OK
        options.history = false  unless u.isString(options.history)
        options.source  = 'keep' unless u.isString(options.source)
    else
      options.transition = options.failTransition
      options.failTransition = undefined
      if isReloadable # e.g. GET returns 500 Internal Server Error
        options.history = url unless options.history is false
        options.source  = url unless options.source  is false
      else # e.g. POST returns 500 Internal Server Error
        options.source  = 'keep'
        options.history = false

    if options.preload
      u.resolvedPromise()
    else
      extract(selector, xhr.responseText, options)



  ###*
  Updates a selector on the current page with the
  same selector from the given HTML string.

  \#\#\#\# Example

  Let's say your curent HTML looks like this:

      <div class="one">old one</div>
      <div class="two">old two</div>

  We now replace the second `<div>`, using an HTML string
  as the source:

      html = '<div class="one">new one</div>' +
             '<div class="two">new two</div>';

      up.extract('.two', html);

  Up.js looks for the selector `.two` in the strings and updates its
  contents in the current page. The current page now looks like this:

      <div class="one">old one</div>
      <div class="two">new two</div>

  Note how only `.two` has changed. The update for `.one` was
  discarded, since it didn't match the selector.

  @function up.extract
  @param {String|Element|jQuery} selectorOrElement
  @param {String} html
  @param {Object} [options]
    See options for [`up.replace`](/up.replace).
  @return {Promise}
    A promise that will be resolved then the selector was updated
    and all animation has finished.
  @experimental
  ###
  extract = (selectorOrElement, html, options) ->
    up.log.group 'Extracting %s from %d bytes of HTML', selectorOrElement, html?.length, ->
      options = u.options(options,
        historyMethod: 'push',
        requireMatch: true,
        keep: true
      )
      selector = resolveSelector(selectorOrElement, options.origin)
      response = parseResponse(html, options)
      options.title ||= response.title()
      # options.keep = u.option(options.keep, { '[up-keep]': '&' })

      up.layout.saveScroll() unless options.saveScroll == false

      options.beforeSwap?()
      deferreds = []

      updateHistory(options)

      for step in parseImplantSteps(selector, options)
        up.log.group 'Updating %s', step.selector, ->
          $old = findOldFragment(step.selector, options)
          $new = response.find(step.selector)?.first()
          if $old && $new
            deferred = swapElements($old, $new, step.pseudoClass, step.transition, options)
            deferreds.push(deferred)

      options.afterSwap?()
      up.motion.when(deferreds...)

  findOldFragment = (selector, options) ->
    # Prefer to replace fragments in an open popup or modal
    first(".up-popup #{selector}") ||
      first(".up-modal #{selector}") ||
      first(selector) ||
      oldFragmentNotFound(selector, options)

  oldFragmentNotFound = (selector, options) ->
    if options.requireMatch
      message = 'Could not find selector %s in current body HTML'
      if message[0] == '#'
        message += ' (avoid using IDs)'
      u.error(message, selector)

  parseResponse = (html, options) ->
    # jQuery cannot construct transient elements that contain <html> or <body> tags
    htmlElement = u.createElementFromHtml(html)
    title: -> htmlElement.querySelector("title")?.textContent
    find: (selector) ->
      # Although we cannot have a jQuery collection from an entire HTML document,
      # we can use jQuery's Sizzle engine to grep through a DOM tree.
      # jQuery.find is the Sizzle function (https://github.com/jquery/sizzle/wiki#public-api)
      # which gives us non-standard CSS selectors such as `:has`.
      # It returns an array of DOM elements, NOT a jQuery collection.
      if child = $.find(selector, htmlElement)[0]
        $(child)
      else if options.requireMatch
        u.error("Could not find selector %s in response %o", selector, html)

  updateHistory = (options) ->
    if options.history
      document.title = options.title if options.title
      up.history[options.historyMethod](options.history)

  swapElements = ($old, $new, pseudoClass, transition, options) ->
    transition ||= 'none'

    if options.source == 'keep'
      options = u.merge(options, source: source($old))

    # Ensure that all transitions and animations have completed.
    up.motion.finish($old)

    if pseudoClass
      # Text nodes are wrapped in a .up-insertion container so we can
      # animate them and measure their position/size for scrolling.
      # This is not possible for container-less text nodes.
      $wrapper = $new.contents().wrap('<span class="up-insertion"></span>').parent()

      # Note that since we're prepending/appending instead of replacing,
      # `$new` will not actually be inserted into the DOM, only its children.
      if pseudoClass == 'before'
        $old.prepend($wrapper)
      else
        $old.append($wrapper)

      # u.copyAttributes($new, $old)

      hello($wrapper.children(), options)

      # Reveal element that was being prepended/appended.
      promise = up.layout.revealOrRestoreScroll($wrapper, options)

      # Since we're adding content instead of replacing, we'll only
      # animate $new instead of morphing between $old and $new
      promise = promise.then -> up.animate($wrapper, transition, options)

      # Remove the wrapper now that is has served it purpose
      promise = promise.then -> u.unwrapElement($wrapper)

    else if keepPlan = findKeepPlan($old, $new, options)
      console.debug("Element is kept directly")
      emitFragmentKept(keepPlan)
      promise = u.resolvedPromise()

    else
      replacement = ->

        options.keepPlans = transferKeepableElements($old, $new, options)

        # Don't insert the new element after the old element. For some reason
        # this will make the browser scroll to the bottom of the new element.
        $new.insertBefore($old)

        updateHistory(options)

        # Remember where the element came from so we can
        # offer reload functionality.
        setSource($new, options.source) unless options.source is false

        autofocus($new)

        # The fragment should be compiled before animating,
        # so transitions see .up-current classes
        hello($new, options)

        # Morphing will also process options.reveal
        up.morph($old, $new, transition, options)

      # Wrap the replacement as a destroy animation, so $old will
      # get marked as .up-destroying right away.
      promise = destroy($old, animation: replacement)

    promise

  transferKeepableElements = ($old, $new, options) ->
    keepPlans = []
    if options.keep
      for keepable in $old.find('[up-keep]')
        $keepable = $(keepable)
        if plan = findKeepPlan($keepable, $new, u.merge(options, descendantsOnly: true))
          # Replace $keepable with its clone so it looks good in a transition between
          # $old and $new. Note that $keepable will still point to the same element
          # after the replacement, which is now detached.
          $keepableClone = $keepable.clone()
          $keepable.replaceWith($keepableClone)
          # Since we're going to swap the entire $old and $new containers afterwards,
          # replace the matching element with $keepable so it will eventually return to the DOM.
          plan.$partner.replaceWith($keepable)
          keepPlans.push(plan)
    keepPlans

  findKeepPlan = ($element, $new, options) ->
    console.debug("### Finding plan for %o (%o / %o)", $element.get(0), options.keep, $element.is('[up-keep]'))
    if options.keep && $element.is('[up-keep]')
      $keepable = $element
      partnerSelector = $keepable.attr('up-keep') || '&'
      partnerSelector = resolveSelector(partnerSelector, $keepable)
      if options.descendantsOnly
        $partner = $new.find(partnerSelector)
      else
        $partner = u.findWithSelf($new, partnerSelector)
      $partner = $partner.first()
      console.debug("Keepable is %o, sister is %o (lookup through %o, $new was %o)", $keepable.get(0), $partner.get(0), partnerSelector, $new)

      if $partner.length && $partner.is('[up-keep]')
        description =
          $element: $keepable               # the element that should be kept
          $partner: $partner                # the element that would have replaced it but now does not
          newData: up.syntax.data($partner) # the parsed up-data attribute of the element we will discard
        keepEventArgs = u.merge(description, message: ['Keeping element %o', $keepable.get(0)])
        if up.bus.nobodyPrevents('up:fragment:keep', keepEventArgs)
          description

  parseImplantSteps = (selector, options) ->
    transitionArg = options.transition || options.animation || 'none'
    comma = /\ *,\ */
    disjunction = selector.split(comma)
    # console.debug("string is %o", transitionArg)
    if u.isString(transitions)
      transitions = transitionArg.split(comma)
    else
      transitions = [transitionArg]
    for selectorAtom, i in disjunction
      # Splitting the atom
      selectorParts = selectorAtom.match(/^(.+?)(?:\:(before|after))?$/)
      selectorParts or u.error('Could not parse selector atom "%s"', selectorAtom)
      selector = selectorParts[1]
      if selector == 'html'
        # If someone really asked us to replace the <html> root, the best
        # we can do is replace the <body>.
        selector = 'body'
      pseudoClass = selectorParts[2]
      transition = transitions[i] || u.last(transitions)
      selector: selector
      pseudoClass: pseudoClass
      transition: transition

  ###*
  Compiles a page fragment that has been inserted into the DOM
  without Up.js.

  **As long as you manipulate the DOM using Up.js, you will never
  need to call this method.** You only need to use `up.hello` if the
  DOM is manipulated without Up.js' involvement, e.g. by setting
  the `innerHTML` property or calling jQuery methods like
  `html`, `insertAfter` or `appendTo`:

      $element = $('.element');
      $element.html('<div>...</div>');
      up.hello($element);

  This function emits the [`up:fragment:inserted`](/up:fragment:inserted)
  event.

  @function up.hello
  @param {String|Element|jQuery} selectorOrElement
  @param {String|Element|jQuery} [options.origin]
  @param {String|Element|jQuery} [options.kept]
  @return {jQuery}
    The compiled element
  @stable
  ###
  hello = (selectorOrElement, options) ->
    $element = $(selectorOrElement)
    options = u.options(options, keepPlans: [])
    keptElements = []
    for plan in options.keepPlans
      console.debug('Emitting kept %o', plan)
      emitFragmentKept(plan)
      keptElements.push(plan.$element)
    console.debug('Called hello with %o kept elements (%o)', keptElements.length, keptElements)
    up.syntax.compile($element, kept: keptElements)
    emitFragmentInserted($element, options)
    $element

  ###*
  When a page fragment has been [inserted or updated](/up.replace),
  this event is [emitted](/up.emit) on the fragment.

  \#\#\#\# Example

      up.on('up:fragment:inserted', function(event, $fragment) {
        console.log("Looks like we have a new %o!", $fragment);
      });

  @event up:fragment:inserted
  @param {jQuery} event.$element
    The fragment that has been inserted or updated.
  @stable
  ###
  emitFragmentInserted = (fragment) ->
    $fragment = $(fragment)
    up.emit 'up:fragment:inserted',
      $element: $fragment
      message: ['Inserted fragment %o', $fragment.get(0)]

  ###*
  DOCUMENT ME

  @event up:fragment:keep
  @param {jQuery} event.$element
    The fragment that has been kept.
  @param {jQuery} event.newData
    The value of the [`up-data`](/up-data) attribute of the discarded element,
    parsed as a JSON object.
  @stable
  ###

  ###*
  DOCUMENT ME

  @event up:fragment:kept
  @param {jQuery} event.$element
    The fragment that has been kept.
  @param {jQuery} event.newData
    The value of the [`up-data`](/up-data) attribute of the discarded element,
    parsed as a JSON object.
  @stable
  ###
  emitFragmentKept = (keepPlan) ->
    eventAttrs = u.merge(keepPlan, message: ['Kept fragment %o', keepPlan.$element.get(0)])
    up.emit('up:fragment:kept', eventAttrs)

  autofocus = ($element) ->
    selector = '[autofocus]:last'
    $control = u.findWithSelf($element, selector)
    if $control.length && $control.get(0) != document.activeElement
      $control.focus()

  isRealElement = ($element) ->
    unreal = '.up-ghost, .up-destroying'
    # Closest matches both the element itself
    # as well as its ancestors
    $element.closest(unreal).length == 0

  ###*
  Returns the first element matching the given selector, but
  ignores elements that are being [destroyed](/up.destroy) or [transitioned](/up.morph).

  If the given argument is already a jQuery collection (or an array
  of DOM elements), the first element matching these conditions
  is returned.

  Returns `undefined` if no element matches these conditions.

  @function up.first
  @param {String|Element|jQuery|Array<Element>} selectorOrElement
  @return {jQuery}
    The first element that is neither a ghost or being destroyed,
    or `undefined` if no such element was given.
  @experimental
  ###
  first = (selectorOrElement) ->
    elements = undefined
    if u.isString(selectorOrElement)
      elements = $(selectorOrElement).get()
    else
      elements = selectorOrElement
    $match = undefined
    for element in elements
      $element = $(element)
      if isRealElement($element)
        $match = $element
        break
    $match

  ###*
  Destroys the given element or selector.

  Takes care that all [`up.compiler`](/up.compiler) destructors, if any, are called.

  The element is removed from the DOM.
  Note that if you choose to animate the element removal using `options.animate`,
  the element won't be removed until after the animation has completed.

  Emits events [`up:fragment:destroy`](/up:fragment:destroy) and [`up:fragment:destroyed`](/up:fragment:destroyed).
  
  @function up.destroy
  @param {String|Element|jQuery} selectorOrElement 
  @param {String} [options.url]
  @param {String} [options.title]
  @param {String|Function} [options.animation='none']
    The animation to use before the element is removed from the DOM.
  @param {Number} [options.duration]
    The duration of the animation. See [`up.animate`](/up.animate).
  @param {Number} [options.delay]
    The delay before the animation starts. See [`up.animate`](/up.animate).
  @param {String} [options.easing]
    The timing function that controls the animation's acceleration. [`up.animate`](/up.animate).
  @return {Deferred}
    A promise that will be resolved once the element has been removed from the DOM.
  @stable
  ###
  destroy = (selectorOrElement, options) ->
    $element = $(selectorOrElement)
    unless $element.is('.up-placeholder, .up-tooltip, .up-modal, .up-popup')
      destroyMessage = ['Destroying fragment %o', $element.get(0)]
      destroyedMessage = ['Destroyed fragment %o', $element.get(0)]
    if up.bus.nobodyPrevents('up:fragment:destroy', $element: $element, message: destroyMessage)
      options = u.options(options, animation: false)
      animateOptions = up.motion.animateOptions(options)
      $element.addClass('up-destroying')
      # If e.g. a modal or popup asks us to restore a URL, do this
      # before emitting `fragment:destroy`. This way up.navigate sees the
      # new URL and can assign/remove .up-current classes accordingly.
      up.history.push(options.url) if u.isPresent(options.url)
      document.title = options.title if u.isPresent(options.title)
      animationDeferred = u.presence(options.animation, u.isDeferred) ||
        up.motion.animate($element, options.animation, animateOptions)
      animationDeferred.then ->
        up.syntax.clean($element)
        # Emit this while $element is still part of the DOM, so event
        # listeners bound to the document will receive the event.
        up.emit 'up:fragment:destroyed', $element: $element, message: destroyedMessage
        $element.remove()
      animationDeferred
    else
      # Although someone prevented the destruction, keep a uniform API for
      # callers by returning a Deferred that will never be resolved.
      $.Deferred()

  ###*
  Before a page fragment is being [destroyed](/up.destroy), this
  event is [emitted](/up.emit) on the fragment.

  If the destruction is animated, this event is emitted before the
  animation begins.

  @event up:fragment:destroy
  @param {jQuery} event.$element
    The page fragment that is about to be destroyed.
  @param event.preventDefault()
    Event listeners may call this method to prevent the fragment from being destroyed.
  @stable
  ###

  ###*
  This event is [emitted](/up.emit) right before a [destroyed](/up.destroy)
  page fragment is removed from the DOM.

  If the destruction is animated, this event is emitted after
  the animation has ended.

  @event up:fragment:destroyed
  @param {jQuery} event.$element
    The page fragment that is about to be removed from the DOM.
  @stable
  ###

  ###*
  Replaces the given element with a fresh copy fetched from the server.

  \#\#\#\# Example

      up.on('new-mail', function() {
        up.reload('.inbox');
      });

  Up.js remembers the URL from which a fragment was loaded, so you
  don't usually need to give an URL when reloading.

  @function up.reload
  @param {String|Element|jQuery} selectorOrElement
  @param {Object} [options]
    See options for [`up.replace`](/up.replace)
  @param {String} [options.url]
    The URL from which to reload the fragment.
    This defaults to the URL from which the fragment was originally loaded.
  @stable
  ###
  reload = (selectorOrElement, options) ->
    options = u.options(options, cache: false)
    sourceUrl = options.url || source(selectorOrElement)
    replace(selectorOrElement, sourceUrl, options)

  up.on 'ready', ->
    $body = $(document.body)
    setSource($body, up.browser.url())
    hello($body)

  knife: eval(Knife?.point)
  replace: replace
  reload: reload
  destroy: destroy
  extract: extract
  first: first
  source: source
  resolveSelector: resolveSelector
  hello: hello

)(jQuery)

up.replace = up.flow.replace
up.extract = up.flow.extract
up.reload = up.flow.reload
up.destroy = up.flow.destroy
up.first = up.flow.first
up.hello = up.flow.hello

