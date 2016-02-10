up.log = (($) ->

  prefix = (message) ->
    "ᴜᴘ #{message}"

  ###*
  Prints a debugging message to the browser console.

  @function up.debug
  @param {String} message
  @param {Array} args...
  @internal
  ###
  debug = (message, args...) ->
    if message
      up.browser.puts('debug', prefix(message), args...)

  ###*
  Prints a logging message to the browser console.

  @function up.puts
  @param {String} message
  @param {Array} args...
  @internal
  ###
  puts = (message, args...) ->
    if message
      up.browser.puts('log', prefix(message), args...)

  ###*
  @function up.log.warn
  @internal
  ###
  warn = (message, args...) ->
    if message
      up.browser.puts('warn', prefix(message), args...)

  ###*
  - Makes sure the group always closes
  - Does not make a group if the message is nil

  @function up.log.group
  @internal
  ###
  group = (message, args...) ->
    block = args.pop() # Coffeescript copies the arguments array
    if message
      up.browser.puts('groupCollapsed', prefix(message), args...)
      try
        block()
      finally
        console.groupEnd() if message
    else
      block()

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
    if args[0]
      args[0] = prefix(args[0])
      up.browser.puts('error', args...)

  puts: puts
  debug: debug
  error: error
  warn: warn
  group: group

)(jQuery)

up.puts = up.log.puts
