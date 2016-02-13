describe 'up.syntax', ->
  
  describe 'Javascript functions', ->
  
    describe 'up.compiler', ->
      
      it 'applies an event initializer whenever a matching fragment is inserted', ->
  
        observeClass = jasmine.createSpy()
        up.compiler '.child', ($element) ->
          observeClass($element.attr('class'))
  
        up.hello(affix('.container .child'))
   
        expect(observeClass).not.toHaveBeenCalledWith('container')
        expect(observeClass).toHaveBeenCalledWith('child')           
  
      it 'lets allows initializers return a destructor function, which is called when a compiled fragment gets destroyed', ->
  
        destructor = jasmine.createSpy()
        up.compiler '.child', ($element) ->
          destructor
  
        up.hello(affix('.container .child'))
        expect(destructor).not.toHaveBeenCalled()
        
        up.destroy('.container')
        expect(destructor).toHaveBeenCalled()

      it 'parses an up-data attribute as JSON and passes the parsed object as a second argument to the initializer', ->

        observeArgs = jasmine.createSpy()
        up.compiler '.child', ($element, data) ->
          observeArgs($element.attr('class'), data)

        data = { key1: 'value1', key2: 'value2' }

        $tag = affix(".child").attr('up-data', JSON.stringify(data))
        up.hello($tag)

        expect(observeArgs).toHaveBeenCalledWith('child', data)

      it 'passes an empty object as a second argument to the initializer if there is no up-data attribute', ->

        observeArgs = jasmine.createSpy()
        up.compiler '.child', ($element, data) ->
          observeArgs($element.attr('class'), data)

        up.hello(affix(".child"))

        expect(observeArgs).toHaveBeenCalledWith('child', {})

      describe 'with { keep } option', ->

        it 'adds an up-keep attribute to the fragment during compilation', ->
          throw "implement me"

    describe 'up.hello', ->

      it 'should have tests'
      
     