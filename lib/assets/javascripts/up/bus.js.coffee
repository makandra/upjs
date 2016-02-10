###*
Events
======

Up.js has a convenient way to [listen to DOM events](/up.on):

    up.on('click', 'button', function(event, $button) {
      // $button is a jQuery collection containing
      // the clicked <button> element
    });

This is roughly equivalent to binding an event listener to `document`
using jQuery's [`on`](http://api.jquery.com/on/).

- Event listeners on [unsupported browsers](/up.browser.isSupported) are silently discarded,
  leaving you with an application without Javascript. This is typically preferable to
  a soup of randomly broken Javascript in ancient browsers.
- A jQuery object with the target element is automatically passed to the event handler.
- You can [attach structured data](/up.on#attaching-structured-data) to observed elements.
- The call is shorter.

Many Up.js interactions also emit DOM events that are prefixed with `up:`.

    up.on('up:modal:opened', function(event) {
      console.log('A new modal has just opened!');
    });

Events often have both present (`up:modal:open`) and past forms (`up:modal:opened`).
You can usually prevent an action by listening to the present form
and call `preventDefault()` on the `event` object:

    up.on('up:modal:open', function(event) {
      if (event.url == '/evil') {
        // Prevent the modal from opening
        event.preventDefault();
      }
    });

@class up.bus
###
up.bus = (($) ->
  
  u = up.util

  # We remember which argument lists have been passed to `up.on`
  # so we can clean out the listener registry between tests.
  liveUpDescriptions = {}
  nextUpDescriptionNumber = 0

  ###*
  Convert an Up.js style listener (second argument is the event target
  as a jQuery collection) to a vanilla jQuery listener

  @function upListenerToJqueryListener
  @internal
  ###
  upListenerToJqueryListener = (upListener) ->
    (event) ->
      $me = event.$element || $(this)
      upListener.apply($me.get(0), [event, $me, up.syntax.data($me)])

  ###*
  Converts an argument list for `up.on` to an argument list for `jQuery.on`.
  This involves rewriting the listener signature in the last argument slot.

  @function upDescriptionToJqueryDescription
  @internal
  ###
  upDescriptionToJqueryDescription = (upDescription, isNew) ->
    jqueryDescription = u.copy(upDescription)
    upListener = jqueryDescription.pop()
    jqueryListener = undefined
    if isNew
      jqueryListener = upListenerToJqueryListener(upListener)
      upListener._asJqueryListener = jqueryListener
      upListener._descriptionNumber = ++nextUpDescriptionNumber
    else
      jqueryListener = upListener._asJqueryListener
      jqueryListener or u.error('up.off: The event listener %o was never registered through up.on')
    jqueryDescription.push(jqueryListener)
    jqueryDescription


  ###*
  Listens to an event on `document`.

  The given event listener which will be executed whenever the
  given event is [triggered](/up.emit) on the given selector:

      up.on('click', '.button', function(event, $element) {
        console.log("Someone clicked the button %o", $element);
      });

  This is roughly equivalent to binding an event listener to `document`:

      $(document).on('click', '.button', function(event) {
        console.log("Someone clicked the button %o", $(this));
      });

  Other than jQuery, Up.js will silently discard event listeners
  on [unsupported browsers](/up.browser.isSupported).

  \#\#\#\# Attaching structured data

  In case you want to attach structured data to the event you're observing,
  you can serialize the data to JSON and put it into an `[up-data]` attribute:

      <span class="person" up-data="{ age: 18, name: 'Bob' }">Bob</span>
      <span class="person" up-data="{ age: 22, name: 'Jim' }">Jim</span>

  The JSON will parsed and handed to your event handler as a third argument:

      up.on('click', '.person', function(event, $element, data) {
        console.log("This is %o who is %o years old", data.name, data.age);
      });

  \#\#\#\# Migrating jQuery event handlers to `up.on`

  Within the event handler, Up.js will bind `this` to the
  native DOM element to help you migrate your existing jQuery code to
  this new syntax.

  So if you had this before:

      $(document).on('click', '.button', function() {
        $(this).something();
      });

  ... you can simply copy the event handler to `up.on`:

      up.on('click', '.button', function() {
        $(this).something();
      });

  \#\#\#\# Stopping to listen

  `up.on` returns a function that unbinds the event listeners when called.

  There is also a function [`up.off`](/up.off) which you can use for the same purpose.

  @function up.on
  @param {String} events
    A space-separated list of event names to bind.
  @param {String} [selector]
    The selector of an element on which the event must be triggered.
    Omit the selector to listen to all events with that name, regardless
    of the event target.
  @param {Function(event, $element, data)} behavior
    The handler that should be called.
    The function takes the affected element as the first argument (as a jQuery object).
    If the element has an `up-data` attribute, its value is parsed as JSON
    and passed as a second argument.
  @return {Function}
    A function that unbinds the event listeners when called.
  @stable
  ###
  live = (upDescription...) ->
    # Silently discard any event handlers that are registered on unsupported
    # browsers and return a no-op destructor
    return (->) unless up.browser.isSupported()

    # Convert the args for up.on to an argument list as expected by jQuery.on.
    jqueryDescription = upDescriptionToJqueryDescription(upDescription, true)

    # Remember the descriptions we registered, so we can
    # clean up after ourselves during a `reset`
    rememberUpDescription(upDescription)

    $(document).on(jqueryDescription...)

    # Return destructor
    -> unbind(upDescription...)

  ###*
  Unregisters an event listener previously bound with [`up.on`](/up.on).

  \#\#\#\# Example

  Let's say you are listing to clicks on `.button` elements:

      var listener = function() { };
      up.on('click', '.button', listener);

  You can stop listening to these events like this:

      up.off('click', '.button', listener);

  Note that you need to pass `up.off` a reference to the same listener function
  that was passed to `up.on` earlier.

  @function up.off
  @stable
  ###
  unbind = (upDescription...) ->
    jqueryDescription = upDescriptionToJqueryDescription(upDescription, false)
    forgetUpDescription(upDescription)
    $(document).off(jqueryDescription...)

  rememberUpDescription = (upDescription) ->
    number = upDescriptionNumber(upDescription)
    liveUpDescriptions[number] = upDescription

  forgetUpDescription = (upDescription) ->
    number = upDescriptionNumber(upDescription)
    delete liveUpDescriptions[number]

  upDescriptionNumber = (upDescription) ->
    u.last(upDescription)._descriptionNumber

  ###*
  Emits a event with the given name and properties.

  The event will be triggered as a jQuery event on `document`.

  Other code can subscribe to events with that name using
  [`up.on`](/up.on) or by [binding a jQuery event listener](http://api.jquery.com/on/) to `document`.

  \#\#\#\# Example

      up.on('my:event', function(event) {
        console.log(event.foo);
      });

      up.emit('my:event', { foo: 'bar' });
      # Prints "bar" to the console

  @function up.emit
  @param {String} eventName
    The name of the event.
  @param {Object} [eventProps={}]
    A list of properties to become part of the event object
    that will be passed to listeners. Note that the event object
    will by default include properties like `preventDefault()`
    or `stopPropagation()`.
  @param {jQuery} [eventProps.$element=$(document)]
    The element on which the event is triggered.
  @experimental
  ###
  emit = (eventName, eventProps = {}) ->
    event = $.Event(eventName, eventProps)
    $target = eventProps.$element || $(document)
    console.groupCollapsed("Emitting %o on %o with props %o", eventName, $target, eventProps)
    $target.trigger(event)
    console.groupEnd()
    event

  ###*
  [Emits an event](/up.emit) and returns whether any listener
  has prevented the default action.

  @function up.bus.nobodyPrevents
  @param {String} eventName
  @param {Object} eventProps
  @experimental
  ###
  nobodyPrevents = (args...) ->
    event = emit(args...)
    not event.isDefaultPrevented()

  ###*
  Registers an event listener to be called when the user
  presses the `Escape` key.

  @function up.bus.onEscape
  @param {Function} listener
    The listener function to register.
  @return {Function}
    A function that unbinds the event listeners when called.
  @experimental
  ###
  onEscape = (listener) ->
    live('keydown', 'body', (event) ->
      if u.escapePressed(event)
        listener(event)
    )

  ###*
  Makes a snapshot of the currently registered event listeners,
  to later be restored through [`up.bus.reset`](/up.bus.reset).

  @internal
  ###
  snapshot = ->
    for description in liveUpDescriptions
      description._isDefault = true

  ###*
  Resets the list of registered event listeners to the
  moment when the framework was booted.

  @internal
  ###
  restoreSnapshot = ->
    doomedDescriptions = u.reject(liveUpDescriptions, (description) -> description._isDefault)
    unbind(description...) for description in doomedDescriptions

  ###*
  Resets Up.js to the state when it was booted.
  All custom event handlers, animations, etc. that have been registered
  will be discarded.

  This is an internal method for to enable unit testing.
  Don't use this in production.

  @function up.reset
  @experimental
  ###
  emitReset = ->
    up.emit('up:framework:reset')

  ###*
  This event is [emitted](/up.emit) when Up.js is [reset](/up.reset) during unit tests.

  @event up:framework:reset
  @experimental
  ###

  ###*
  Boots the Up.js framework.

  This is done automatically by including the Up.js Javascript.

  Up.js will not boot if the current browser is [not supported](/up.browser.isSupported).
  This leaves you with a classic server-side application on legacy browsers.

  Emits the [`up:framework:boot`](/up:framework:boot) event.

  @function up.boot
  @experimental
  ###
  boot = ->
    if up.browser.isSupported()
      up.emit('up:framework:boot')

  ###*
  This event is [emitted](/up.emit) when Up.js [boots](/up.boot).

  @event up:framework:boot
  @experimental
  ###

  live 'up:framework:boot', snapshot
  live 'up:framework:reset', restoreSnapshot

  knife: eval(Knife?.point)
  on: live # can't name symbols `on` in Coffeescript
  off: unbind # can't name symbols `off` in Coffeescript
  emit: emit
  nobodyPrevents: nobodyPrevents
  onEscape: onEscape
  emitReset: emitReset
  boot: boot

)(jQuery)

up.on = up.bus.on
up.off = up.bus.off
up.emit = up.bus.emit
up.reset = up.bus.emitReset
up.boot = up.bus.boot
