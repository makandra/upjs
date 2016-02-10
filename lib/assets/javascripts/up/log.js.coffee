up.log = (($) ->

  ###*
  Prints a debugging message to the browser console.

  @function up.debug
  @param {String} message
  @param {Array} args...
  @internal
  ###
  debug = (message, args...) ->
    if message
      message = "[UP] #{message}"
      up.browser.puts('debug', message, args...)

  ###*
  Prints a logging message to the browser console.

  @function up.log.out
  @param {String} message
  @param {Array} args...
  @internal
  ###
  out = (message, args...) ->
    if message
      message = "[UP] #{message}"
      up.browser.puts('log', message, args...)

  ###*
  @function up.log.warn
  @internal
  ###
  warn = (message, args...) ->
    if message
      message = "[UP] #{message}"
      up.browser.puts('warn', message, args...)

  ###*
  - Makes sure the group always closes
  - Does not make a group if the message is nil

  @function up.log.group
  @internal
  ###
  group = (message, args...) ->
    block = args.pop() # Coffeescript copies the arguments array
    up.browser.puts('groupCollapsed', message, args...) if message
    try
      block()
    finally
      console.groupEnd() if message

  ###*
  Throws a fatal error with the given message.

  - The error will be printed to the [error console](https://developer.mozilla.org/en-US/docs/Web/API/Console/error)
  - An [`Error`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error) (exception) will be thrown, unwinding the current call stack
  - The error message will be printed in a corner of the screen

  \#\#\#\# Examples

      up.error('Division by zero')
      up.error('Unexpected result %o', result)

  @function up.log.error
  @internal
  ###
  error = (args...) ->
    args[0] = "[UP] #{args[0]}"
    up.browser.puts('error', args...)

  CONSOLE_PLACEHOLDERS = /\%[odisf]/g

  evalConsoleTemplate = (args...) ->
    message = args[0]
    i = 0
    maxLength = 80
    message.replace CONSOLE_PLACEHOLDERS, ->
      i += 1
      arg = args[i]
      argType = (typeof arg)
      if argType == 'string'
        arg = arg.replace(/\s+/g, ' ')
        arg = "#{arg.substr(0, maxLength)}…" if arg.length > maxLength
        arg = "\"#{arg}\""
      else if argType == 'undefined'
        # JSON.stringify(undefined) is actually undefined
        arg = 'undefined'
      else if argType == 'number' || argType == 'function'
        arg = arg.toString()
      else
        arg = JSON.stringify(arg)
      if arg.length > maxLength
        arg = "#{arg.substr(0, maxLength)} …"
        # For truncated objects or functions, add a trailing brace so
        # long log lines are easier to parse visually
        if argType == 'object' || argType == 'function'
          arg += " }"
      arg

  out: out
  debug: debug
  error: error
  warn: warn
  group: group
  evalConsoleTemplate: evalConsoleTemplate

)(jQuery)
