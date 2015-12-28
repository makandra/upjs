###*
Forms and controls
==================
  
Up.js comes with functionality to submit forms without
leaving the current page. This means you can replace page fragments,
open dialogs with sub-forms, etc. all without losing form state.
  
\#\#\# Incomplete documentation!
  
We need to work on this page:
  
- Explain how to display form errors
- Explain that the server needs to send 2xx or 5xx status codes so
  Up.js can decide whether the form submission was successful
- Explain that the server needs to send `X-Up-Location` and `X-Up-Method` headers
  if an successful form submission resulted in a redirect
- Examples

@class up.form
###
up.form = (($) ->
  
  u = up.util

  ###*
  Sets default options for form submission and validation.

  @property up.form.config
  @param {Array} [config.validateTargets=['[up-fieldset]:has(&)', 'fieldset:has(&)', 'label:has(&)', 'form:has(&)']]
    An array of CSS selectors that are searched around a form field
    that wants to [validate](/up.validate). The first matching selector
    will be updated with the validation messages from the server.

    By default this looks for a `<fieldset>`, `<label>` or `<form>`
    around the validating input field, or any element with an
    `up-fieldset` attribute.
  ###
  config = u.config
    validateTargets: ['[up-fieldset]:has(&)', 'fieldset:has(&)', 'label:has(&)', 'form:has(&)']

  reset = ->
    config.reset()

  ###*
  Submits a form via AJAX and updates a page fragment with the response.

      up.submit('form.new-user')
  
  Instead of loading a new page, the form is submitted via AJAX.
  The response is parsed for a CSS selector and the matching elements will
  replace corresponding elements on the current page.

  The `<form>` element will be assigned a CSS class `up-active` while
  the submission is loading.
  
  @function up.submit
  @param {Element|jQuery|String} formOrSelector
    A reference or selector for the form to submit.
    If the argument points to an element that is not a form,
    Up.js will search its ancestors for the closest form.
  @param {String} [options.url]
    The URL where to submit the form.
    Defaults to the form's `action` attribute, or to the current URL of the browser window.
  @param {String} [options.method]
    The HTTP method used for the form submission.
    Defaults to the form's `up-method`, `data-method` or `method` attribute, or to `'post'`
    if none of these attributes are given.
  @param {String} [options.target]
    The selector to update when the form submission succeeds (server responds with status 200).
    Defaults to the form's `up-target` attribute, or to `'body'`.
  @param {String} [options.failTarget]
    The selector to update when the form submission fails (server responds with non-200 status).
    Defaults to the form's `up-fail-target` attribute, or to an auto-generated
    selector that matches the form itself.
  @param {Boolean|String} [options.history=true]
    Successful form submissions will add a history entry and change the browser's
    location bar if the form either uses the `GET` method or the response redirected
    to another page (this requires the `upjs-rails` gem).
    If want to prevent history changes in any case, set this to `false`.
    If you pass a `String`, it is used as the URL for the browser history.
  @param {String} [options.transition='none']
    The transition to use when a successful form submission updates the `options.target` selector.
    Defaults to the form's `up-transition` attribute, or to `'none'`.
  @param {String} [options.failTransition='none']
    The transition to use when a failed form submission updates the `options.failTarget` selector.
    Defaults to the form's `up-fail-transition` attribute, or to `options.transition`, or to `'none'`.
  @param {Number} [options.duration]
    The duration of the transition. See [`up.morph`](/up.morph).
  @param {Number} [options.delay]
    The delay before the transition starts. See [`up.morph`](/up.morph).
  @param {String} [options.easing]
    The timing function that controls the transition's acceleration. [`up.morph`](/up.morph).
  @param {Element|jQuery|String} [options.reveal]
    Whether to reveal the target element within its viewport.
  @param {Boolean} [options.restoreScroll]
    If set to `true`, this will attempt to [`restore scroll positions`](/up.restoreScroll)
    previously seen on the destination URL.
  @param {Boolean} [options.cache]
    Whether to force the use of a cached response (`true`)
    or never use the cache (`false`)
    or make an educated guess (`undefined`).

    By default only responses to `GET` requests are cached
    for a few minutes.
  @param {Object} [options.headers={}]
    An object of additional header key/value pairs to send along
    with the request.
  @return {Promise}
    A promise for the successful form submission.
  ###
  submit = (formOrSelector, options) ->
    
    $form = $(formOrSelector).closest('form')

    options = u.options(options)
    successSelector = up.flow.resolveSelector(u.option(options.target, $form.attr('up-target'), 'body'), options)
    failureSelector = up.flow.resolveSelector(u.option(options.failTarget, $form.attr('up-fail-target'), -> u.createSelectorFromElement($form)), options)
    historyOption = u.option(options.history, u.castedAttr($form, 'up-history'), true)
    successTransition = u.option(options.transition, u.castedAttr($form, 'up-transition'))
    failureTransition = u.option(options.failTransition, u.castedAttr($form, 'up-fail-transition'), successTransition)
    httpMethod = u.option(options.method, $form.attr('up-method'), $form.attr('data-method'), $form.attr('method'), 'post').toUpperCase()

    implantOptions = {}
    implantOptions.reveal = u.option(options.reveal, u.castedAttr($form, 'up-reveal'), true)
    implantOptions.cache = u.option(options.cache, u.castedAttr($form, 'up-cache'))
    implantOptions.restoreScroll = u.option(options.restoreScroll, u.castedAttr($form, 'up-restore-scroll'))
    implantOptions.origin = u.option(options.origin, $form)
    implantOptions = u.extend(implantOptions, up.motion.animateOptions(options, $form))

    useCache = u.option(options.cache, u.castedAttr($form, 'up-cache'))
    url = u.option(options.url, $form.attr('action'), up.browser.url())
    
    $form.addClass('up-active')
    
    if !up.browser.canPushState() && historyOption != false
      $form.get(0).submit()
      return

    request = {
      url: url
      method: httpMethod
      data: $form.serialize()
      selector: successSelector
      cache: useCache
      headers: options.headers
    }

    successUrl = (xhr) ->
      url = undefined
      if u.isGiven(historyOption)
        if historyOption == false || u.isString(historyOption)
          url = historyOption
        else if currentLocation = u.locationFromXhr(xhr)
          url = currentLocation
        else if request.type == 'GET'
          url = request.url + '?' + request.data
      u.option(url, false)

    up.proxy.ajax(request)
      .always ->
        $form.removeClass('up-active')
      .done (html, textStatus, xhr) ->
        successOptions = u.merge(implantOptions,
          history: successUrl(xhr),
          transition: successTransition
        )
        up.flow.implant(successSelector, html, successOptions)
      .fail (xhr, textStatus, errorThrown) ->
        html = xhr.responseText
        failureOptions = u.merge(implantOptions, transition: failureTransition)
        up.flow.implant(failureSelector, html, failureOptions)

  ###*
  Observes a form field and runs a callback when its value changes.
  This is useful for observing text fields while the user is typing.

  For instance, the following would submit the form whenever the
  text field value changes:

      up.observe('input[name=query]', { change: function(value, $input) {
        up.submit($input)
      } });

  \#\#\#\# Preventing concurrency

  Firing asynchronous code after a form field can cause
  [concurrency issues](https://makandracards.com/makandra/961-concurrency-issues-with-find-as-you-type-boxes).

  To mitigate this, `up.observe` will try to never run a callback
  before the previous callback has completed.
  To take advantage of this, your callback code must return a promise.
  Note that all asynchronous Up.js functions return promises.

  \#\#\#\# Throttling

  If you are concerned about fast typists causing too much
  load on your server, you can use a `delay` option to wait
  a few miliseconds before executing the callback:

      up.observe('input', {
        delay: 100,
        change: function(value, $input) { up.submit($input) }
      });

  @function up.observe
  @param {Element|jQuery|String} fieldOrSelector
  @param {Function(value, $field)|String} options.change
    The callback to execute when the field's value changes.
    If given as a function, it must take two arguments (`value`, `$field`).
    If given as a string, it will be evaled as Javascript code in a context where
    (`value`, `$field`) are set.
  @param {Number} [options.delay=0]
    The number of miliseconds to wait before executing the callback
    after the input value changes. Use this to limit how often the callback
    will be invoked for a fast typist.
  ###
  observe = (fieldOrSelector, options) ->

    $field = $(fieldOrSelector)
    options = u.options(options)
    delay = u.option($field.attr('up-delay'), options.delay, 0)
    delay = parseInt(delay)

    knownValue = null
    callback = null
    callbackTimer = null

    if codeOnChange = $field.attr('up-observe')
      callback = (value, $field) ->
        eval(codeOnChange)
    else if options.change
      callback = options.change
    else
      u.error('up.observe: No change callback given')

    callbackPromise = u.resolvedPromise()

    # This holds the next callback function, curried with `value` and `$field`.
    # Since we're waiting for callback promises to resolve before running
    # another callback, this might be overwritten while we're waiting for a
    # previous callback to finish.
    nextCallback = null

    runNextCallback = ->
      if nextCallback
        returnValue = nextCallback()
        nextCallback = null
        returnValue

    check = ->
      value = $field.val()
      # don't run the callback for the check during initialization
      skipCallback = u.isNull(knownValue)
      if knownValue != value
        knownValue = value
        unless skipCallback
          clearTimer()
          nextCallback = -> callback.apply($field.get(0), [value, $field])
          callbackTimer = setTimeout(
            ->
              # Only run the callback once the previous callback's
              # promise resolves.
              callbackPromise.then ->
                returnValue = runNextCallback()
                # If the callback returns a promise, we will remember it
                # and chain additional callback invocations to it.
                if u.isPromise(returnValue)
                  callbackPromise = returnValue
                else
                  callbackPromise = u.resolvedPromise()
          , delay
          )

    clearTimer = ->
      clearTimeout(callbackTimer)

    changeEvents = if up.browser.canInputEvent()
      # Actually we only need `input`, but we want to notice
      # if another script manually triggers `change` on the element.
      'input change'
    else
      # Actually we won't ever get `input` from the user in this browser,
      # but we want to notice if another script  manually triggers `input`
      # on the element.
      'input change keypress paste cut click propertychange'
    $field.on changeEvents, check

    check()

    # return destructor
    return clearTimer

  resolveValidateTarget = ($field, options) ->
    target = u.option(options.target, $field.attr('up-validate'))
    if u.isBlank(target)
      target ||= u.detect(config.validateTarget, (defaultTarget) ->
        resolvedDefault = up.flow.resolveSelector(defaultTarget)
        $field.closest(resolvedDefault).length
      )
    if u.isBlank(target)
      error('Could not find default validation target for %o (tried ancestors %o)', $field, config.validateTargets)
    unless u.isString(target)
      target = u.createSelectorFromElement(target)
    target

  ###*
  Performs a server-side validation of a form and
  update the form with validation messages.

  `up.validate` submits the given field's form with an additional `X-Up-Validate`
  HTTP header. Upon seeing this header, the server is expected to validate (but not save)
  the form submission and render a new copy of the form with validation errors.

  \#\#\#\# Example

      <form action="/users">

        <label>
          E-mail: <input type="text" name="email" />
        </label>

        <label>
          Password: <input type="password" name="password" />
        </label>

      </form>

  We call:

      up.validate('input[name=email]')

  On Rails with upjs-rails gem:

      class UsersController < ApplicationController

        # This action handles POST /users
        def create
          @user = User.new(params[:user])
          if request.headers['X-Up-Validate']
            @user.valid?    # run validations, but don't save to the database
            render 'form'    # render form with error messages
          elsif @user.save?
            sign_in @user
          else
            render 'form', status: :bad_request
          end
        end
      end

  Note that with the upjs-rails gem you can say `up.validate?`
  instead of manually checking for `request.headers['X-Up-Validate']`.

  \#\#\#\# How validation results are displayed

  Although the server will usually respond to a validation with a complete
  fresh copy of the form, Up.js will by default not update the entire form.
  This is done in order to preserve volatile state such as the scroll position
  of `<textarea>` elements.

  By default Up.js looks for a `<fieldset>`, `<label>` or `<form>`
  around the validating input field, or any element with an
  `up-fieldset` attribute.

  You can change this default behavior by setting `up.config.validateTargets`:

      // Always update the entire form containing the current field ("&")
      up.config.validateTargets = ['form &']

  You can also individually override what to update using the `target` option:

      up.validate('input[name=email]', { target: '.email-errors' })

  \#\#\#\# Fields that are dependent on each other

      <form action="/contracts">
        <select name="department_id">...</select> <!-- options for all departments -->
        <select name="employee_id">...</select> <!-- options for all employees of selected department -->
      </form>


      <%= form_for @contract do |form| %>
        <%= form.collection_select :department_id, Department.all, :id, :name %>
        <%= form.collection_select :employee_id, @contract.department.employees, :id, :name %>
      <% end %>

  ...

      up.validate('[name=department]', { target: '[name=employees]' })

  @function up.validate
  @param {String|Element|jQuery} fieldOrSelector
  @param {String|Element|jQuery} [options.target]
  ###
  validate = (fieldOrSelector, options) ->
    $field = $(fieldOrSelector)
    options = u.options(options)
    options.target = resolveValidateTarget($field, options)
    options.failTarget = options.target
    options.history = false
    options.origin = $field
    options.headers = u.option(options.headers, {})
    # Make sure the X-Up-Validate header is present, so the server-side
    # knows that it should not persist the form submission
    options.headers['X-Up-Validate'] = $field.attr('name') || '__none__'
    options = u.merge(options, up.motion.animateOptions(options, $field))
    $form = $field.closest('form')
    promise = up.submit($form, options)
    promise

  ###*
  Submits the form through AJAX, searches the response for the selector
  given in `up-target` and [replaces](/up.replace) the selector content in the current page:

      <form method="post" action="/users" up-target=".main">
        ...
      </form>

  @selector form[up-target]
  @param {String} up-target
    The selector to [replace](/up.replace) if the form submission is successful (200 status code).
  @param {String} [up-fail-target]
    The selector to [replace](/up.replace) if the form submission is not successful (non-200 status code).
    If omitted, Up.js will replace the `<form>` tag itself, assuming that the
    server has echoed the form with validation errors.
  @param {String} [up-transition]
    The animation to use when the form is replaced after a successful submission.
  @param {String} [up-fail-transition]
    The animation to use when the form is replaced after a failed submission.
  @param {String} [up-history='true']
  @param {String} [up-method]
    The HTTP method to be used to submit the form (`get`, `post`, `put`, `delete`, `patch`).
    Alternately you can use an attribute `data-method`
    ([Rails UJS](https://github.com/rails/jquery-ujs/wiki/Unobtrusive-scripting-support-for-jQuery))
    or `method` (vanilla HTML) for the same purpose.
  @param {String} [up-reveal='true']
    Whether to reveal the target element within its viewport before updating.
  @param {String} [up-restore-scroll='false']
    Whether to restore previously known scroll position of all viewports
    within the target selector.
  @param {String} [up-cache]
    Whether to force the use of a cached response (`true`)
    or never use the cache (`false`)
    or make an educated guess (`undefined`).

    By default only responses to `GET` requests are cached for a few minutes.
  ###
  up.on 'submit', 'form[up-target]', (event, $form) ->
    event.preventDefault()
    submit($form)

  ###*
  ...

  @selector [up-validate]
  ###
  up.on 'change', '[up-validate]', (event, $field) ->
    validate($field)

  ###*
  Observes this form field and runs the given script
  when its value changes. This is useful for observing text fields
  while the user is typing.

  For instance, the following would submit the form whenever the
  text field value changes:

      <form method="GET" action="/search">
        <input type="query" up-observe="up.form.submit(this)">
      </form>

  The script given with `up-observe` runs with the following context:

  | Name     | Type      | Description                           |
  | -------- | --------- | ------------------------------------- |
  | `value`  | `String`  | The current value of the field        |
  | `this`   | `Element` | The form field                        |
  | `$field` | `jQuery`  | The form field as a jQuery collection |

  See up.observe.

  @selector input[up-observe]
    The code to run when the field's value changes.
  @param {String} up-observe
  ###
  up.compiler '[up-observe]', ($field) ->
    return observe($field)

#  up.compiler '[up-autosubmit]', ($field) ->
#    return observe($field, change: ->
#      $form = $field.closest('form')
#      $field.addClass('up-active')
#      up.submit($form).always ->
#        $field.removeClass('up-active')
#    )

  up.on 'up:framework:reset', reset

  submit: submit
  observe: observe
  validate: validate

)(jQuery)

up.submit = up.form.submit
up.observe = up.form.observe
up.validate = up.form.validate

