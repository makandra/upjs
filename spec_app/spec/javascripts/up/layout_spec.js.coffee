describe 'up.layout', ->

  u = up.util

  describe 'Javascript functions', ->

    describe 'up.reveal', ->

      beforeEach ->
        up.layout.defaults
          snap: 0
          substance: 99999
          viewports: [document]

      describe 'when the viewport is the document', ->

        beforeEach ->
          $body = $('body')

          @$elements = []
          @$container = $('<div class="container">').prependTo($body)

          @clientHeight = u.clientSize().height

          for height in [@clientHeight, '50px', '5000px']
            $element = $('<div>').css(height: height)
            $element.appendTo(@$container)
            @$elements.push($element)

        afterEach ->
          @$container.remove()

        it 'reveals the given element', ->
          up.reveal(@$elements[0])
          # ---------------------
          # [0] 0 .......... ch-1
          # ---------------------
          # [1] ch+0 ...... ch+49
          # [2] ch+50 ... ch+5049
          expect($(document).scrollTop()).toBe(0)

          up.reveal(@$elements[1])
          # ---------------------
          # [0] 0 .......... ch-1
          # [1] ch+0 ...... ch+49
          # ---------------------
          # [2] ch+50 ... ch+5049
          expect($(document).scrollTop()).toBe(50)

          up.reveal(@$elements[2])
          # [0] 0 .......... ch-1
          # [1] ch+0 ...... ch+49
          # ---------------------
          # [2] ch+50 ... ch+5049
          # ---------------------
          expect($(document).scrollTop()).toBe(@clientHeight + 50)

        it 'snaps to the top if the space above the future-visible area is smaller than the value of config.snap', ->

          up.layout.defaults(snap: 30)

          @$elements[0].css(height: '20px')

          up.reveal(@$elements[2])
          # [0] 0 ............ 19
          # [1] 20 ........... 69
          # ---------------------
          # [2] 70 ......... 5069
          # ---------------------
          expect($(document).scrollTop()).toBe(70)

          # Even though we're revealing the second element, the viewport
          # snaps to the top edge.
          up.reveal(@$elements[1])
          # ---------------------
          # [0] 0 ............ 19
          # [1] 20 ........... 69
          # ---------------------
          # [2] 70 ......... 5069
          expect($(document).scrollTop()).toBe(0)

        it 'scrolls far enough so the element is not obstructed by an element fixed to the top', ->
          $topNav = affix('[up-fixed=top]').css(
            position: 'fixed',
            top: '0',
            left: '0',
            right: '0'
            height: '100px'
          )

          up.reveal(@$elements[0], viewport: @viewport)
          # ---------------------
          # [F] 0 ............ 99
          # [0] 0 .......... ch-1
          # ---------------------
          # [1] ch+0 ...... ch+49
          # [2] ch+50 ... ch+5049
          expect($(document).scrollTop()).toBe(0) # would need to be -100

          up.reveal(@$elements[1])
          # ---------------------
          # [F] 0 ............ 99
          # [0] 00000 ...... ch-1
          # [1] ch+0 ...... ch+49
          # ---------------------
          # [2] ch+50 ... ch+5049

          expect($(document).scrollTop()).toBe(50)

          up.reveal(@$elements[2])
          # [0] 00000 ...... ch-1
          # [1] ch+0 ...... ch+49
          # ---------------------
          # [F] 0 ............ 99
          # [2] ch+50 ... ch+5049
          # ----------------
          expect($(document).scrollTop()).toBe(@clientHeight + 50 - 100)

          up.reveal(@$elements[1])
          # [0] 00000 ...... ch-1
          # ---------------------
          # [F] 0 ............ 99
          # [1] ch+0 ...... ch+49
          # [2] ch+50 ... ch+5049
          # ----------------
          expect($(document).scrollTop()).toBe(@clientHeight + 50 - 100 - 50)


        it 'scrolls far enough so the element is not obstructed by an element fixed to the bottom', ->
          $bottomNav = affix('[up-fixed=bottom]').css(
            position: 'fixed',
            bottom: '0',
            left: '0',
            right: '0'
            height: '100px'
          )

          up.reveal(@$elements[0])
          # ---------------------
          # [0] 0 .......... ch-1
          # [F] 0 ............ 99
          # ---------------------
          # [1] ch+0 ...... ch+49
          # [2] ch+50 ... ch+5049
          expect($(document).scrollTop()).toBe(0)

          up.reveal(@$elements[1])
          # ---------------------
          # [0] 0 .......... ch-1
          # [1] ch+0 ...... ch+49
          # [F] 0 ............ 99
          # ---------------------
          # [2] ch+50 ... ch+5049
          expect($(document).scrollTop()).toBe(150)

          up.reveal(@$elements[2])
          # ---------------------
          # [0] 0 .......... ch-1
          # [1] ch+0 ...... ch+49
          # ---------------------
          # [2] ch+50 ... ch+5049
          # [F] 0 ............ 99
          expect($(document).scrollTop()).toBe(@clientHeight + 50)


      describe 'when the viewport is a container with overflow-y: scroll', ->

        it 'reveals the given element', ->
          $viewport = affix('div').css
            'position': 'absolute'
            'top': '50px'
            'left': '50px'
            'width': '100px'
            'height': '100px'
            'overflow-y': 'scroll'
          $elements = []
          u.each [0..5], ->
            $element = $('<div>').css(height: '50px')
            $element.appendTo($viewport)
            $elements.push($element)

          # ------------
          # [0] 000..049
          # [1] 050..099
          # ------------
          # [2] 100..149
          # [3] 150..199
          # [4] 200..249
          # [5] 250..399
          expect($viewport.scrollTop()).toBe(0)

          # See that the view only scrolls down as little as possible
          # in order to reveal the element
          up.reveal($elements[3], viewport: $viewport)
          # [0] 000..049
          # [1] 050..099
          # ------------
          # [2] 100..149
          # [3] 150..199
          # ------------
          # [4] 200..249
          # [5] 250..299
          expect($viewport.scrollTop()).toBe(100)

          # See that the view doesn't move if the element
          # is already revealed
          up.reveal($elements[2], viewport: $viewport)
          expect($viewport.scrollTop()).toBe(100)

          # See that the view scrolls as far down as it cans
          # to show the bottom element
          up.reveal($elements[5], viewport: $viewport)
          # [0] 000..049
          # [1] 050..099
          # [2] 100..149
          # [3] 150..199
          # ------------
          # [4] 200..249
          # [5] 250..299
          # ------------
          expect($viewport.scrollTop()).toBe(200)

          # See that the view only scrolls up as little as possible
          # in order to reveal the element
          up.reveal($elements[1], viewport: $viewport)
          # [0] 000..049
          # ------------
          # [1] 050..099
          # [2] 100..149
          # ------------
          # [3] 150..199
          # [4] 200..249
          # [5] 250..299
          expect($viewport.scrollTop()).toBe(50)

      it 'only reveals the top number of pixels defined in config.substance', ->

        up.layout.defaults
          substance: 20

        $viewport = affix('div').css
          'position': 'absolute'
          'top': '50px'
          'left': '50px'
          'width': '100px'
          'height': '100px'
          'overflow-y': 'scroll'
        $elements = []
        u.each [0..5], ->
          $element = $('<div>').css(height: '50px')
          $element.appendTo($viewport)
          $elements.push($element)

        # [0] 000..049
        # [1] 050..099
        # [2] 100..149
        # [3] 150..199
        # [4] 200..249
        # [5] 250..299

        # Viewing 0 .. 99
        expect($viewport.scrollTop()).toBe(0)

        # See that the view only scrolls down as little as possible
        # in order to reveal the first 20 rows of the element
        up.reveal($elements[3], viewport: $viewport)
        # Viewing 70 to 169
        expect($viewport.scrollTop()).toBe(50 + 20)

        # See that the view doesn't move if the element
        # is already revealed
        up.reveal($elements[2], viewport: $viewport)
        expect($viewport.scrollTop()).toBe(50 + 20)

        # See that the view scrolls as far down as it cans
        # to show the first 20 rows of the bottom element
        up.reveal($elements[5], viewport: $viewport)
        # Viewing 170 to 269
        expect($viewport.scrollTop()).toBe(150 + 20)

        # See that the view only scrolls up as little as possible
        # in order to reveal the first 20 rows element
        up.reveal($elements[2], viewport: $viewport)
        # Viewing 100 to 199
        expect($viewport.scrollTop()).toBe(100)

    describe 'up.layout.viewportsWithin', ->

      it 'should have tests'

    describe 'up.layout.viewportsOf', ->

      it 'seeks upwards from the given element', ->
        up.layout.defaults(viewports: ['.viewport1', '.viewport2'])
        $viewport1 = affix('.viewport1')
        $viewport2 = affix('.viewport2')
        $element = affix('div').appendTo($viewport2)
        expect(up.layout.viewportOf($element)).toEqual($viewport2)

      it 'returns the given element if it is a configured viewport itself', ->
        up.layout.defaults(viewports: ['.viewport'])
        $viewport = affix('.viewport')
        expect(up.layout.viewportOf($viewport)).toEqual($viewport)

      it 'finds the document if the viewport is the document', ->
        # This actually tests that the hierarchy returned by `$.parent`
        # is $element => ... => $('body') => $('html') => $(document)
        up.layout.defaults(viewports: [document])
        $element = affix('div')
        expect(up.layout.viewportOf($element)).toEqual($(document))

      it 'throws an error if no viewport could be found', ->
        up.layout.defaults(viewports: ['.does-not-exist'])
        $element = affix('div')
        lookup = -> up.layout.viewportOf($element)
        expect(lookup).toThrowError(/Could not find viewport/i)

    describe 'up.scroll', ->

      it 'should have tests'
