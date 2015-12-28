describe 'up.form', ->
  
  describe 'Javascript functions', ->
    
    describe 'up.observe', ->

      it 'should have tests'

    describe 'up.submit', ->
      
      if up.browser.canPushState()
      
        beforeEach ->
          $form = affix('form[action="/path/to"][method="put"][up-target=".response"]')
          $form.append('<input name="field1" value="value1">')
          $form.append('<input name="field2" value="value2">')
    
          affix('.response').text('old-text')
    
          @promise = up.submit($form)
    
          @request = @lastRequest()
          expect(@request.url).toMatch /\/path\/to$/
          expect(@request.method).toBe 'PUT'
          expect(@request.data()).toEqual
            field1: ['value1']
            field2: ['value2']
        
        it 'submits the given form and replaces the target with the response', (done) ->
    
          @respondWith """
            text-before

            <div class="response">
              new-text
            </div>

            text-after
            """
    
          @promise.then ->
            expect($('.response')).toHaveText('new-text')
            expect($('body')).not.toHaveText('text-before')
            expect($('body')).not.toHaveText('text-after')
            done()
        
        it 'places the response into the form if the submission returns a 5xx status code', (done) ->
          @request.respondWith
            status: 500
            contentType: 'text/html'
            responseText:
              """
              text-before
    
              <form>
                error-messages
              </form>
    
              text-after
              """
    
          @promise.always ->
            expect($('.response')).toHaveText('old-text')
            expect($('form')).toHaveText('error-messages')
            expect($('body')).not.toHaveText('text-before')
            expect($('body')).not.toHaveText('text-after')
            done()
        
        it 'respects a X-Up-Location header that the server sends in case of a redirect', (done) ->
    
          @request.respondWith
            status: 200
            contentType: 'text/html'
            responseHeaders: { 'X-Up-Location': '/other/path' }
            responseText:
              """
              <div class="response">
                new-text
              </div>
              """
    
          @promise.then ->
            expect(up.browser.url()).toMatch(/\/other\/path$/)
            done()
            
      else
        
        it 'submits the given form', ->
          $form = affix('form[action="/path/to"][method="put"][up-target=".response"]')
          form = $form.get(0)
          spyOn(form, 'submit')
          
          up.submit($form)
          expect(form.submit).toHaveBeenCalled()

  describe 'unobtrusive behavior', ->

    describe 'form[up-target]', ->

      it 'rigs the form to use up.submit instead of a standard submit'

    describe 'input[up-observe]', ->

      it 'should have tests'

    describe 'input[up-validate]', ->

      it "submits the input's form with an 'X-Up-Validate' header and replaces the given selector with the response", ->

        $form = affix('form[action="/path/to"]')
        $group = $("""
          <div class="field-group">
            <input name="user" value="judy" up-validate=".field-group:has(&)">
          </div>
        """).appendTo($form)
        $group.find('input').trigger('change')

        request = @lastRequest()
        expect(request.requestHeaders['X-Up-Validate']).toEqual('user')
        expect(request.requestHeaders['X-Up-Selector']).toEqual(".field-group:has([name='user'])")

        @respondWith """
          <div class="field-group has-error">
            <div class='error'>Username has already been taken</div>
            <input name="user" value="judy" up-validate=".field-group:has(&)">
          </div>
        """

        $group = $('.field-group')
        expect($group.length).toBe(1)
        expect($group).toHaveClass('has-error')
        expect($group).toHaveText('Username has already been taken')

      it 'finds a form group around the input field', ->
        expect(1).toBe(2)
