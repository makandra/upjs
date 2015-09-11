describe 'up.navigation', ->
  
  describe 'unobtrusive behavior', ->

    it 'marks a link as .up-current if it links to the current URL', ->
      spyOn(up.browser, 'url').and.returnValue('/foo')
      $currentLink = up.ready(affix('a[href="/foo"]'))
      $otherLink = up.ready(affix('a[href="/bar"]'))
      expect($currentLink).toHaveClass('up-current')
      expect($otherLink).not.toHaveClass('up-current')
      
    it 'marks any link as .up-current if its up-href attribute matches the current URL', ->
      spyOn(up.browser, 'url').and.returnValue('/foo')
      $currentLink = up.ready(affix('span[up-href="/foo"]'))
      $otherLink = up.ready(affix('span[up-href="/bar"]'))
      expect($currentLink).toHaveClass('up-current')
      expect($otherLink).not.toHaveClass('up-current')

    it 'marks any link as .up-current if any of its space-separated up-alias values matches the current URL', ->
      spyOn(up.browser, 'url').and.returnValue('/foo')
      $currentLink = up.ready(affix('span[up-alias="/aaa /foo /bbb"]'))
      $otherLink = up.ready(affix('span[up-alias="/bar"]'))
      expect($currentLink).toHaveClass('up-current')
      expect($otherLink).not.toHaveClass('up-current')

    it 'does not throw if the current location does not match an up-alias wildcard (bugfix)', ->
      inserter = -> up.ready(affix('a[up-alias="/qqqq*"]'))
      expect(inserter).not.toThrow()

    it 'does not highlight a link to "#" (commonly used for JS-only buttons)', ->
      $link = up.ready(affix('a[href="#"]'))
      expect($link).not.toHaveClass('up-current')

    it 'marks URL prefixes as .up-current if an up-alias value ends in *', ->
      spyOn(up.browser, 'url').and.returnValue('/foo/123')
      $currentLink = up.ready(affix('span[up-alias="/aaa /foo/* /bbb"]'))
      $otherLink = up.ready(affix('span[up-alias="/bar"]'))
      expect($currentLink).toHaveClass('up-current')
      expect($otherLink).not.toHaveClass('up-current')

    it 'allows to configure a custom "current" class, but always also sets .up-current', ->
      up.navigation.defaults(currentClasses: ['highlight'])
      spyOn(up.browser, 'url').and.returnValue('/foo')
      $currentLink = up.ready(affix('a[href="/foo"]'))
      expect($currentLink).toHaveClass('highlight up-current')

    if up.browser.canPushState()
      
      it 'marks a link as .up-current if it links to the current URL, but is missing a trailing slash', ->
        $link = affix('a[href="/foo"][up-target=".main"]')
        affix('.main')
        $link.click()
        @lastRequest().respondWith
          status: 200
          contentType: 'text/html'
          responseHeaders: { 'X-Up-Location': '/foo/' }
          responseText: '<div class="main">new-text</div>'
        expect($link).toHaveClass('up-current')
      
      it 'marks a link as .up-current if it links to the current URL, but has an extra trailing slash', ->
        $link = affix('a[href="/foo/"][up-target=".main"]')
        affix('.main')
        $link.click()
        @lastRequest().respondWith
          status: 200
          contentType: 'text/html'
          responseHeaders: { 'X-Up-Location': '/foo' }
          responseText: '<div class="main">new-text</div>'
        expect($link).toHaveClass('up-current')

      it 'marks a link as .up-current if it links to the URL currently shown in the modal'

      it 'marks a link as .up-current if it links to the URL currently shown in the popup'

      it 'changes .up-current marks as the URL changes'
        
      it 'marks clicked links as .up-active until the request finishes', ->
        $link = affix('a[href="/foo"][up-target=".main"]')
        affix('.main')
        $link.click()
#        console.log($link)
        expect($link).toHaveClass('up-active')
        @lastRequest().respondWith
          status: 200
          contentType: 'text/html'
          responseText: '<div class="main">new-text</div>'
        expect($link).not.toHaveClass('up-active')
        expect($link).toHaveClass('up-current')
        
      it 'marks links with [up-instant] on mousedown as .up-active until the request finishes', ->
        $link = affix('a[href="/foo"][up-instant][up-target=".main"]')
        affix('.main')
        Trigger.mousedown($link)
        expect($link).toHaveClass('up-active')
        @lastRequest().respondWith
          status: 200
          contentType: 'text/html'
          responseText: '<div class="main">new-text</div>'
        expect($link).not.toHaveClass('up-active')
        expect($link).toHaveClass('up-current')
    
      it 'prefers to mark an enclosing [up-expand] click area', ->
        $area = affix('div[up-expand] a[href="/foo"][up-target=".main"]')
        up.ready($area)
        $link = $area.find('a')
        affix('.main')
        $link.click()
        expect($area).toHaveClass('up-active')
        @lastRequest().respondWith
          status: 200
          contentType: 'text/html'
          responseText: '<div class="main">new-text</div>'
        expect($area).toHaveClass('up-current')
        