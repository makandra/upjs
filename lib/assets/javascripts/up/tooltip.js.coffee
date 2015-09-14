###*
Tooltips
========
  
Elements that have an `up-tooltip` attribute will show the attribute
value in a tooltip when a user hovers over the element. 
  
\#\#\# Incomplete documentation!
  
We need to work on this page:
  
- Show the tooltip's HTML structure and how to style the elements
- Explain how to position tooltips using `up-position`
- We should have a position about tooltips that contain HTML.
  

@class up.tooltip
###
up.tooltip = (->
  
  u = up.util

  setPosition = ($link, $tooltip, position) ->
    linkBox = u.measure($link)
    tooltipBox = u.measure($tooltip)
    css = switch position
      when "top"
        left: linkBox.left + 0.5 * (linkBox.width - tooltipBox.width)
        top: linkBox.top - tooltipBox.height
      when "bottom"
        left: linkBox.left + 0.5 * (linkBox.width - tooltipBox.width)
        top: linkBox.top + linkBox.height
      else
        u.error("Unknown position %o", position)
    $tooltip.attr('up-position', position)
    $tooltip.css(css)

  createElement = (html) ->
    u.$createElementFromSelector('.up-tooltip')
      .html(html)
      .appendTo(document.body)

  ###*
  Opens a tooltip over the given element.

      up.tooltip.open('.help', {
        html: 'Enter multiple words or phrases'
      });
  
  @method up.tooltip.open
  @param {Element|jQuery|String} elementOrSelector
  @param {String} [options.html]
    The HTML to display in the tooltip.
  @param {String} [options.position='top']
    The position of the tooltip. Known values are `top` and `bottom`.
  @param {String} [options.animation]
    The animation to use when opening the tooltip.
  ###
  open = (linkOrSelector, options = {}) ->
    $link = $(linkOrSelector)
    html = u.option(options.html, $link.attr('up-tooltip'), $link.attr('title'))
    position = u.option(options.position, $link.attr('up-position'), 'top')
    animation = u.option(options.animation, u.castedAttr($link, 'up-animation'), 'fade-in')
    animateOptions = up.motion.animateOptions(options, $link)
    close()
    $tooltip = createElement(html)
    setPosition($link, $tooltip, position)
    up.animate($tooltip, animation, animateOptions)

  ###*
  Closes a currently shown tooltip.
  Does nothing if no tooltip is currently shown.
  
  @method up.tooltip.close
  @param {Object} options
    See options for [`up.animate`](/up.motion#up.animate).
  ###
  close = (options) ->
    $tooltip = $('.up-tooltip')
    if $tooltip.length
      options = u.options(options, animation: 'fade-out')
      options = u.merge(options, up.motion.animateOptions(options))
      up.destroy($tooltip, options)

  ###*
  Displays a tooltip when hovering the mouse over this element:

      <a href="/decks" up-tooltip="Show all decks">Decks</a>
  
  You can also make an existing `title` attribute appear as a tooltip:
  
      <a href="/decks" title="Show all decks" up-tooltip>Decks</a>

  @method [up-tooltip]
  @ujs
  ###
  up.compiler('[up-tooltip]', ($link) ->
    # Don't register these events on document since *every*
    # mouse move interaction  bubbles up to the document. 
    $link.on('mouseover', -> open($link))
    $link.on('mouseout', -> close())
  )

  # Close the tooltip when someone clicks anywhere.
  up.on('click', 'body', (event, $body) ->
    close()
  )

  # The framework is reset between tests, so also close
  # a currently open tooltip.
  up.bus.on 'framework:reset', close

  # Close the tooltip when the user presses ESC.
  up.magic.onEscape(-> close())

  open: open
  close: close

)()
