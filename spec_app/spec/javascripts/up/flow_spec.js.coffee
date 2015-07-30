describe 'up.flow', ->
  
  describe 'Javascript functions', ->

    describe 'up.replace', ->

      if up.browser.canPushState()

        beforeEach ->

          affix('.before').text('old-before')
          affix('.middle').text('old-middle')
          affix('.after').text('old-after')

          @responseText =
            """
            <div class="before">new-before</div>
            <div class="middle">new-middle</div>
            <div class="after">new-after</div>
            """

          @respond = ->
            jasmine.Ajax.requests.mostRecent().respondWith
              status: 200
              contentType: 'text/html'
              responseText: @responseText

        it 'replaces the given selector with the same selector from a freshly fetched page', (done) ->
          @request = up.replace('.middle', '/path')
          @respond()
          @request.then ->
            expect($('.before')).toHaveText('old-before')
            expect($('.middle')).toHaveText('new-middle')
            expect($('.after')).toHaveText('old-after')
            done()
          
        it 'should set the browser location to the given URL', (done) ->
          @request = up.replace('.middle', '/path')
          @respond()
          @request.then ->
            expect(window.location.pathname).toBe('/path')
            done()
            
        it 'marks the element with the URL from which it was retrieved', (done) ->
          @request = up.replace('.middle', '/path')
          @respond()
          @request.then ->
            expect($('.middle').attr('up-source')).toMatch(/\/path$/)
            done()
            
        it 'replaces multiple selectors separated with a comma', (done) ->
          @request = up.replace('.middle, .after', '/path')
          @respond()
          @request.then ->
            expect($('.before')).toHaveText('old-before')
            expect($('.middle')).toHaveText('new-middle')
            expect($('.after')).toHaveText('new-after')
            done()

        it 'prepends instead of replacing when the target has a :before pseudo-selector', (done) ->
          @request = up.replace('.middle:before', '/path')
          @respond()
          @request.then ->
            expect($('.before')).toHaveText('old-before')
            expect($('.middle')).toHaveText('new-middleold-middle')
            expect($('.after')).toHaveText('old-after')
            done()

        it 'appends instead of replacing when the target has a :after pseudo-selector', (done) ->
          @request = up.replace('.middle:after', '/path')
          @respond()
          @request.then ->
            expect($('.before')).toHaveText('old-before')
            expect($('.middle')).toHaveText('old-middlenew-middle')
            expect($('.after')).toHaveText('old-after')
            done()

        it "lets the developer choose between replacing/prepending/appending for each selector", (done) ->
          @request = up.replace('.before:before, .middle, .after:after', '/path')
          @respond()
          @request.then ->
            expect($('.before')).toHaveText('new-beforeold-before')
            expect($('.middle')).toHaveText('new-middle')
            expect($('.after')).toHaveText('old-afternew-after')
            done()

        it 'executes those script-tags in the response that get inserted into the DOM', (done) ->
          window.scriptTagExecuted = jasmine.createSpy('scriptTagExecuted')

          @responseText =
            """
            <div class="before">
              new-before
              <script type="text/javascript">
                window.scriptTagExecuted('before')
              </script>
            </div>
            <div class="middle">
              new-middle
              <script type="text/javascript">
                window.scriptTagExecuted('middle')
              </script>
            </div>
            """

          @request = up.replace('.middle', '/path')
          @respond()

          @request.then ->
            expect(window.scriptTagExecuted).not.toHaveBeenCalledWith('before')
            expect(window.scriptTagExecuted).toHaveBeenCalledWith('middle')
            done()

      else
        
        it 'makes a full page load', ->
          spyOn(up.browser, 'loadPage')
          up.replace('.selector', '/path')
          expect(up.browser.loadPage).toHaveBeenCalledWith('/path', jasmine.anything())
          
    describe 'up.flow.implant', ->
      
      it 'Updates a selector on the current page with the same selector from the given HTML string', ->

        affix('.before').text('old-before')
        affix('.middle').text('old-middle')
        affix('.after').text('old-after')

        html =
          """
          <div class="before">new-before</div>
          <div class="middle">new-middle</div>
          <div class="after">new-after</div>
          """

        up.flow.implant('.middle', html)

        expect($('.before')).toHaveText('old-before')
        expect($('.middle')).toHaveText('new-middle')
        expect($('.after')).toHaveText('old-after')

      it "throws an error if the selector can't be found on the current page", ->
        html = '<div class="foo-bar">text</div>'
        implant = -> up.flow.implant('.foo-bar', html)
        expect(implant).toThrowError(/Could not find selector ".foo-bar" in current body/i)

      it "throws an error if the selector can't be found in the given HTML string", ->
        affix('.foo-bar')
        implant = -> up.flow.implant('.foo-bar', '')
        expect(implant).toThrowError(/Could not find selector ".foo-bar" in response/i)


    describe 'up.destroy', ->
      
      it 'removes the element with the given selector', ->
        affix('.element')
        up.destroy('.element')
        expect($('.element')).not.toExist()
        
      it 'calls destructors for custom elements', ->
        up.addParser('.element', ($element) -> destructor)
        destructor = jasmine.createSpy('destructor')
        up.ready(affix('.element'))
        up.destroy('.element')
        expect(destructor).toHaveBeenCalled()
        
    describe 'up.reload', ->
      
      if up.browser.canPushState()
      
        it 'reloads the given selector from the closest known source URL', (done) ->
          affix('.container[up-source="/source"] .element').find('.element').text('old text')
    
          up.reload('.element').then ->
            expect($('.element')).toHaveText('new text')
            done()
            
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.url).toMatch(/\/source$/)
    
          request.respondWith
            status: 200
            contentType: '/text/html'
            responseText:
              """
              <div class="container">
                <div class="element">new text</div>
              </div>
              """
            
      else
        
        it 'makes a page load from the closest known source URL', ->
          affix('.container[up-source="/source"] .element').find('.element').text('old text')
          spyOn(up.browser, 'loadPage')
          up.reload('.element')
          expect(up.browser.loadPage).toHaveBeenCalledWith('/source', jasmine.anything())
          
  
    describe 'up.reset', ->
  
      it 'should have tests'
