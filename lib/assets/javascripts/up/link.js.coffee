###*
Linking to page fragments
=========================

Just like in a classical web application, an Up.js app renders a series of *full HTML pages* on the server.

Let's say we are rendering three pages with a tabbed navigation to switch between screens:

```
  /pages/a                /pages/b                /pages/c

+---+---+---+           +---+---+---+           +---+---+---+
| A | B | C |           | A | B | C |           | A | B | C |
|   +--------  (click)  +---+   +----  (click)  +---+---+   |
|           |  ======>  |           |  ======>  |           |
|  Page A   |           |  Page B   |           |  Page C   |
|           |           |           |           |           |
+-----------|           +-----------|           +-----------|
```

Your HTML could look like this:

```
<nav>
  <a href="/pages/a">A</a>
  <a href="/pages/b">B</a>
  <a href="/pages/b">C</a>
</nav>

<article>
  Page A
</article>
```

Using this document-oriented way of navigating between pages
is not a good fit for modern applications, for a multitude of reasons:

- State changes caused by AJAX updates get lost during the page transition.
- Unsaved form changes get lost during the page transition.
- The Javascript VM is reset during the page transition.
- If the page layout is composed from multiple srollable containers
  (e.g. a pane view), the scroll positions get lost during the page transition.
- The user sees a "flash" as the browser loads and renders the new page,
  even if large portions of the old and new page are the same (navigation, layout, etc.).


Smoother flow by updating fragments
-----------------------------------

In Up.js you annotate navigation links with an `up-target` attribute.
The value of this attribute is a CSS selector that indicates which page
fragment to update.

Since we only want to update the `<article>` tag, we will use `up-target="article"`:


```
<nav>
  <a href="/pages/a" up-target="article">A</a>
  <a href="/pages/b" up-target="article">B</a>
  <a href="/pages/b" up-target="article">C</a>
</nav>
```

Instead of `article` you can use any other CSS selector (e. g.  `#main .article`).

With these `up-target` annotations Up.js only updates the targeted part of the screen.
Javascript will not be reloaded, no white flash during a full page reload.


Read on
-------
- You can [animate page transitions](/up.motion) by definining animations for fragments as they enter or leave the screen.
- The `up-target` mechanism also works with [forms](/up.form).
- As you switch through pages, Up.js will [update your browser's location bar and history](/up.history)
- You can [open fragments in popups or modal dialogs](/up.modal).
- You can give users [immediate feedback](/up.navigation) when a link is clicked or becomes current, without waiting for the server.
- [Controlling Up.js pragmatically through Javascript](/up.flow)
- [Defining custom tags and event handlers](/up.magic)

  
@class up.link
###

up.link = (->

  u = up.util
  
  ###*
  Visits the given URL without a full page load.
  This is done by fetching `url` through an AJAX request
  and replacing the current `<body>` element with the response's `<body>` element.

  For example, this would fetch the `/users` URL:

      up.visit('/users')

  @method up.visit
  @param {String} url
    The URL to visit.
  @param {String} [options.target='body']
    The selector to replace.
    See options for [`up.replace`](/up.flow#up.replace)
  @param {Object} options
    See options for [`up.replace`](/up.flow#up.replace)
  ###
  visit = (url, options) ->
    options = u.options(options)
    selector = u.option(options.target, 'body')
    up.replace(selector, url, options)

  ###*
  Follows the given link via AJAX and replaces a CSS selector in the current page
  with corresponding elements from a new page fetched from the server.

  Any Up.js UJS attributes on the given link will be honored. E. g. you have this link:

      <a href="/users" up-target=".main">Users</a>

  You can update the page's `.main` selector with the `.main` from `/users` like this:

      var $link = $('a:first'); // select link with jQuery
      up.follow($link);

  @method up.follow
  @param {Element|jQuery|String} link
    An element or selector which resolves to an `<a>` tag
    or any element that is marked up with an `up-href` attribute.
  @param {String} [options.target]
    The selector to replace.
    Defaults to the `up-target` attribute on `link`,
    or to `body` if such an attribute does not exist.
  @param {Function|String} [options.transition]
    A transition function or name.
  @param {Element|jQuery|String} [options.reveal]
    Whether to reveal the followed element within its viewport.
  @param {Number} [options.duration]
    The duration of the transition. See [`up.morph`](/up.motion#up.morph).
  @param {Number} [options.delay]
    The delay before the transition starts. See [`up.morph`](/up.motion#up.morph).
  @param {String} [options.easing]
    The timing function that controls the transition's acceleration. [`up.morph`](/up.motion#up.morph).
  ###
  follow = (link, options) ->
    $link = $(link)

    options = u.options(options)
    url = u.option($link.attr('up-href'), $link.attr('href'))
    selector = u.option(options.target, $link.attr('up-target'), 'body')
    options.transition = u.option(options.transition, $link.attr('up-transition'), $link.attr('up-animation')) 
    options.history = u.option(options.history, $link.attr('up-history'))
    options.reveal = u.option(options.reveal, $link.attr('up-reveal'))
    options.cache = u.option(options.cache, $link.attr('up-cache'))
    options.restoreScroll = u.option(options.restoreScroll, $link.attr('up-restore-scroll'))
    options.method = followMethod($link, options)
    options = u.merge(options, up.motion.animateOptions(options, $link))

    up.replace(selector, url, options)

  ###*
  @protected
  @method up.link.followMethod
  ###
  followMethod = ($link, options) ->
    options = u.options(options)
    u.option(options.method, $link.attr('up-method'), $link.attr('data-method'), 'get').toUpperCase()

  ###*
  Follows this link via AJAX and replaces a CSS selector in the current page
  with corresponding elements from a new page fetched from the server:

      <a href="/posts/5" up-target=".main">Read post</a>

  \#\#\#\# Updating multiple fragments

  You can update multiple fragments from a single request by separating
  separators with a comma (like in CSS). E.g. if opening a post should
  also update a bubble showing the number of unread posts, you might
  do this:

      <a href="/posts/5" up-target=".main, .unread-count">Read post</a>

  \#\#\#\# Appending or prepending instead of replacing

  By default Up.js will replace the given selector with the same
  selector from a freshly fetched page. Instead of replacing you
  can *append* the loaded content to the existing content by using the
  `:after` pseudo selector. In the same fashion, you can use `:before`
  to indicate that you would like the *prepend* the loaded content.

  A practical example would be a paginated list of items. Below the list is
  a button to load the next page. You can append to the existing list
  by using `:after` in the `up-target` selector like this:

      <ul class="tasks">
        <li>Wash car</li>
        <li>Purchase supplies</li>
        <li>Fix tent</li>
      </ul>

      <a href="/page/2" class="next-page" up-target=".tasks:after, .next-page">
        Load more tasks
      </a>

  \#\#\#\# Following elements that are no links

  You can also use `[up-target]` to turn an arbitrary element into a link.
  In this case, put the link's destination into the `up-href` attribute:

      <button up-target=".main" up-href="/foo/bar">Go</button>

  Note that using any element other than `<a>` will prevent users from
  opening the destination in a new tab.

  @method a[up-target]
  @ujs
  @param {String} up-target
    The CSS selector to replace
  @param [up-href]
    The destination URL to follow.
    If omitted, the the link's `href` attribute will be used.
  @param [up-restore-scroll='false']
    Whether to restore the scroll position of all viewports
    within the target selector.
  ###
  up.on 'click', 'a[up-target], [up-href][up-target]', (event, $link) ->
    if shouldProcessLinkEvent(event, $link)
      if $link.is('[up-instant]')
        # If the link was already processed on mousedown, we still need
        # to prevent the later click event's default behavior.
        event.preventDefault()
      else
        event.preventDefault()
        follow($link)

  ###*
  By adding an `up-instant` attribute to a link, the destination will be
  fetched on `mousedown` instead of `click` (`mouseup`).

      <a href="/users" up-target=".main" up-instant>User list</a>

  This will save precious milliseconds that otherwise spent
  on waiting for the user to release the mouse button. Since an
  AJAX request will be triggered right way, the interaction will
  appear faster.

  Note that using `[up-instant]` will prevent a user from canceling a link
  click by moving the mouse away from the interaction area. However, for
  navigation actions this isn't needed. E.g. popular operation
  systems switch tabs on `mousedown` instead of `click`.

  @method a[up-instant]
  @ujs
  ###
  up.on 'mousedown', 'a[up-instant], [up-href][up-instant]', (event, $link) ->
    if shouldProcessLinkEvent(event, $link)
      event.preventDefault()
      follow($link)

  ###*
  @method up.link.childClicked
  @private
  ###
  childClicked = (event, $link) ->
    $target = $(event.target)
    $targetLink = $target.closest('a, [up-href]')
    $targetLink.length && $link.find($targetLink).length
    
  shouldProcessLinkEvent = (event, $link) ->
    u.isUnmodifiedMouseEvent(event) && !childClicked(event, $link)
    
  ###*
  If applied on a link, Follows this link via AJAX and replaces the
  current `<body>` element with the response's `<body>` element.

  Example:

      <a href="/users" up-follow>User list</a>

  To only update a fragment instead of the entire page,
  see [`up-target`](#up-target).

  \#\#\#\# Turn any element into a link

  You can also use `[up-follow]` to turn an arbitrary element into a link.
  In this case, put the link's destination into the `up-href` attribute:

      <span up-follow up-href="/foo/bar">Go</span>

  Note that using any element other than `<a>` will prevent users from
  opening the destination in a new tab.

  @method a[up-follow]
  @ujs
  @param [up-href]
    The destination URL to follow.
    If omitted, the the link's `href` attribute will be used.
  @param [up-restore-scroll='false']
    Whether to restore the scroll position of all viewports
    within the response.
  ###
  up.on 'click', 'a[up-follow], [up-href][up-follow]', (event, $link) ->
    if shouldProcessLinkEvent(event, $link)
      if $link.is('[up-instant]')
        # If the link was already processed on mousedown, we still need
        # to prevent the later click event's default behavior.
        event.preventDefault()
      else
        event.preventDefault()
        follow($link)

  ###*
  Add an `up-expand` class to any element that contains a link
  in order to enlarge the link's click area:

      <div class="notification" up-expand>
        Record was saved!
        <a href="/records">Close</a>
      </div>

  In the example above, clicking anywhere within `.notification` element
  would [follow](#up-follow) the *Close* link.

  `up-expand` honors all the UJS behavior in expanded links
  (`up-target`, `up-instant`, `up-preload`, etc.).

  @ujs
  @method [up-expand]
  ###
  up.compiler '[up-expand]', ($fragment) ->
    link = $fragment.find('a, [up-href]').get(0)
    link or u.error('No link to expand within %o', $fragment)
    upAttributePattern = /^up-/
    newAttrs = {}
    newAttrs['up-href'] = $(link).attr('href')
    for attribute in link.attributes
      name = attribute.name
      if name.match(upAttributePattern)
        newAttrs[name] = attribute.value
    # Make sure that the containing area will be considered a link
    u.isGiven(newAttrs['up-target']) or newAttrs['up-follow'] = ''
    u.setMissingAttrs($fragment, newAttrs)
    $fragment.removeAttr('up-expand')
  
  ###*
  Marks up the current link to be followed *as fast as possible*.
  This is done by:
  
  - [Following the link through AJAX](/up.link#up-target) instead of a full page load
  - [Preloading the link's destination URL](/up.proxy#up-preload)
  - [Triggering the link on `mousedown`](/up.link#up-instant) instead of on `click`
  
  Use `up-dash` like this:
  
      <a href="/users" up-dash=".main">User list</a>
  
  Note that this is shorthand for:
  
      <a href="/users" up-target=".main" up-instant up-preload>User list</a>  

  @method [up-dash]
  @ujs
  ###
  up.compiler '[up-dash]', ($element) ->
    target = $element.attr('up-dash')
    newAttrs = {
      'up-preload': 'true',
      'up-instant': 'true'
    }
    if u.isBlank(target) || u.castsToTrue(target)
      newAttrs['up-follow'] = ''
    else
      newAttrs['up-target'] = target
    u.setMissingAttrs($element, newAttrs)
    $element.removeAttr('up-dash')

  knife: eval(Knife?.point)
  visit: visit
  follow: follow
  childClicked: childClicked
  followMethod: followMethod

)()

up.visit = up.link.visit
up.follow = up.link.follow
