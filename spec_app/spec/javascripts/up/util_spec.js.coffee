describe 'up.util', ->
  
  describe 'Javascript functions', ->

#    describe 'up.util.argNames', ->
#
#      it 'returns an array of argument names for the given function', ->
#        fun = ($element, data) ->
#        expect(up.util.argNames(fun)).toEqual(['$element', 'data'])

    describe 'up.util.only', ->

      it 'returns a copy of the given object with only the given whitelisted properties', ->
        original =
          foo: 'foo-value'
          bar: 'bar-value'
          baz: 'baz-value'
          bam: 'bam-value'
        whitelisted = up.util.only(original, 'bar', 'bam')
        expect(whitelisted).toEqual
          bar: 'bar-value'
          bam: 'bam-value'
        # Show that original did not change
        expect(original).toEqual
          foo: 'foo-value'
          bar: 'bar-value'
          baz: 'baz-value'
          bam: 'bam-value'

    describe 'up.util.except', ->

      it 'returns a copy of the given object but omits the given blacklisted properties', ->
        original =
          foo: 'foo-value'
          bar: 'bar-value'
          baz: 'baz-value'
          bam: 'bam-value'
        whitelisted = up.util.except(original, 'foo', 'baz')
        expect(whitelisted).toEqual
          bar: 'bar-value'
          bam: 'bam-value'
        # Show that original did not change
        expect(original).toEqual
          foo: 'foo-value'
          bar: 'bar-value'
          baz: 'baz-value'
          bam: 'bam-value'

    describe 'up.util.selectorForElement', ->

      it "prefers using the element's 'up-id' attribute to using the element's ID", ->
        $element = affix('div[up-id=up-id-value]#id-value')
        expect(up.util.selectorForElement($element)).toBe("[up-id='up-id-value']")

      it "prefers using the element's ID to using the element's name", ->
        $element = affix('div#id-value[name=name-value]')
        expect(up.util.selectorForElement($element)).toBe("#id-value")

      it "prefers using the element's name to using the element's classes", ->
        $element = affix('div[name=name-value].class1.class2')
        expect(up.util.selectorForElement($element)).toBe("[name='name-value']")

      it "prefers using the element's classes to using the element's tag name", ->
        $element = affix('div.class1.class2')
        expect(up.util.selectorForElement($element)).toBe(".class1.class2")

      it "uses the element's tag name if no better description is available", ->
        $element = affix('div')
        expect(up.util.selectorForElement($element)).toBe("div")


    describe 'up.util.castedAttr', ->

      it 'returns true if the attribute value is the string "true"', ->
        $element = affix('div').attr('foo', 'true')
        expect(up.util.castedAttr($element, 'foo')).toBe(true)

      it 'returns false if the attribute value is the string "false"', ->
        $element = affix('div').attr('foo', 'false')
        expect(up.util.castedAttr($element, 'foo')).toBe(false)

      it 'returns undefined if the element has no such attribute', ->
        $element = affix('div')
        expect(up.util.castedAttr($element, 'foo')).toBe(undefined)

      it 'returns the attribute value unchanged if the value is some string', ->
        $element = affix('div').attr('foo', 'some text')
        expect(up.util.castedAttr($element, 'foo')).toBe('some text')

    describe 'up.util.any', ->

      it 'returns true if an element in the array returns true for the given function', ->
        result = up.util.any [null, undefined, 'foo', ''], up.util.isPresent
        expect(result).toBe(true)

      it 'returns false if no element in the array returns true for the given function', ->
        result = up.util.any [null, undefined, ''], up.util.isPresent
        expect(result).toBe(false)

      it 'short-circuits once an element returns true', ->
        count = 0
        up.util.any [null, undefined, 'foo', ''], (element) ->
          count += 1
          up.util.isPresent(element)
        expect(count).toBe(3)

    describe 'up.util.all', ->

      it 'returns true if all element in the array returns true for the given function', ->
        result = up.util.all ['foo', 'bar', 'baz'], up.util.isPresent
        expect(result).toBe(true)

      it 'returns false if an element in the array returns false for the given function', ->
        result = up.util.all ['foo', 'bar', null, 'baz'], up.util.isPresent
        expect(result).toBe(false)

      it 'short-circuits once an element returns false', ->
        count = 0
        up.util.all ['foo', 'bar', '', 'baz'], (element) ->
          count += 1
          up.util.isPresent(element)
        expect(count).toBe(3)

    describe 'up.util.isBlank', ->
  
      it 'returns false for false', ->
        expect(up.util.isBlank(false)).toBe(false)
        
      it 'returns false for true', ->
        expect(up.util.isBlank(true)).toBe(false)
  
      it 'returns true for null', ->
        expect(up.util.isBlank(null)).toBe(true)
        
      it 'returns true for undefined', ->
        expect(up.util.isBlank(undefined)).toBe(true)
        
      it 'returns true for an empty String', ->
        expect(up.util.isBlank('')).toBe(true)
        
      it 'returns false for a String with at least one character', ->
        expect(up.util.isBlank('string')).toBe(false)
        
      it 'returns true for an empty array', ->
        expect(up.util.isBlank([])).toBe(true)
        
      it 'returns false for an array with at least one element', ->
        expect(up.util.isBlank(['element'])).toBe(false)

      it 'returns true for an empty object', ->
        expect(up.util.isBlank({})).toBe(true)

      it 'returns true for an object with at least one key', ->
        expect(up.util.isBlank({key: 'value'})).toBe(false)

    describe 'up.util.normalizeUrl', ->

      it 'normalizes a relative path', ->
        expect(up.util.normalizeUrl('foo')).toBe("http://#{location.hostname}:#{location.port}/foo")

      it 'normalizes an absolute path', ->
        expect(up.util.normalizeUrl('/foo')).toBe("http://#{location.hostname}:#{location.port}/foo")

      it 'normalizes a full URL', ->
        expect(up.util.normalizeUrl('http://example.com/foo/bar')).toBe('http://example.com/foo/bar')

    describe 'up.util.detect', ->

      it 'finds the first element in the given array that matches the given tester', ->
        array = ['foo', 'bar', 'baz']
        tester = (element) -> element[0] == 'b'
        expect(up.util.detect(array, tester)).toEqual('bar')

      it "returns undefined if the given array doesn't contain a matching element", ->
        array = ['foo', 'bar', 'baz']
        tester = (element) -> element[0] == 'z'
        expect(up.util.detect(array, tester)).toBeUndefined()

    describe 'up.util.config', ->

      it 'creates an object with the given attributes', ->
        object = up.util.config(a: 1, b: 2)
        expect(object.a).toBe(1)
        expect(object.b).toBe(2)

      it 'does not allow to set a key that was not included in the factory settings', ->
        object = up.util.config(a: 1)
        object.b = 2
        expect(object.b).toBeUndefined()

      describe '#reset', ->

        it 'resets the object to its original state', ->
          object = up.util.config(a: 1)
          expect(object.b).toBeUndefined()
          object.a = 2
          expect(object.a).toBe(2)
          object.reset()
          expect(object.a).toBe(1)

        it 'does not remove the #reset or #update method from the object', ->
          object = up.util.config(a: 1)
          object.b = 2
          object.reset()
          expect(object.reset).toBeDefined()

    describe 'up.util.requestDataAsQuery', ->

      encodedOpeningBracket = '%5B'
      encodedClosingBracket = '%5D'
      encodedSpace = '%20'

      it 'returns the query section for the given object', ->
        string = up.util.requestDataAsQuery('foo-key': 'foo value', 'bar-key': 'bar value')
        expect(string).toEqual("foo-key=foo#{encodedSpace}value&bar-key=bar#{encodedSpace}value")

      it 'returns the query section for the given nested object', ->
        string = up.util.requestDataAsQuery('foo-key': { 'bar-key': 'bar-value' }, 'bam-key': 'bam-value')
        expect(string).toEqual("foo-key#{encodedOpeningBracket}bar-key#{encodedClosingBracket}=bar-value&bam-key=bam-value")

      it 'returns the query section for the given array with { name } and { value } keys', ->
        string = up.util.requestDataAsQuery([
          { name: 'foo-key', value: 'foo value' },
          { name: 'bar-key', value: 'bar value' }
        ])
        expect(string).toEqual("foo-key=foo#{encodedSpace}value&bar-key=bar#{encodedSpace}value")

      it 'returns an empty string for an empty object', ->
        string = up.util.requestDataAsQuery({})
        expect(string).toEqual('')

      it 'returns an empty string for an empty string', ->
        string = up.util.requestDataAsQuery('')
        expect(string).toEqual('')

      it 'returns an empty string for undefined', ->
        string = up.util.requestDataAsQuery(undefined)
        expect(string).toEqual('')

      it 'URL-encodes characters in the key and value', ->
        string = up.util.requestDataAsQuery({ 'äpfel': 'bäume' })
        expect(string).toEqual('%C3%A4pfel=b%C3%A4ume')

      it 'URL-encodes plus characters', ->
        string = up.util.requestDataAsQuery({ 'my+key': 'my+value' })
        expect(string).toEqual('my%2Bkey=my%2Bvalue')


    describe 'up.util.requestDataAsArray', ->

      it 'normalized null to an empty array', ->
        array = up.util.requestDataAsArray(null)
        expect(array).toEqual([])

      it 'normalized undefined to an empty array', ->
        array = up.util.requestDataAsArray(undefined)
        expect(array).toEqual([])

      it 'normalizes an object hash to an array of objects with { name } and { value } keys', ->
        array = up.util.requestDataAsArray(
          'foo-key': 'foo-value'
          'bar-key': 'bar-value'
        )
        expect(array).toEqual([
          { name: 'foo-key', value: 'foo-value' },
          { name: 'bar-key', value: 'bar-value' },
        ])

      it 'normalizes a nested object hash to a flat array using param naming conventions', ->
        array = up.util.requestDataAsArray(
          'foo-key': 'foo-value'
          'bar-key': {
            'bam-key': 'bam-value'
            'baz-key': {
              'qux-key': 'qux-value'
            }
          }
        )
        expect(array).toEqual([
          { name: 'foo-key', value: 'foo-value' },
          { name: 'bar-key[bam-key]', value: 'bam-value' },
          { name: 'bar-key[baz-key][qux-key]', value: 'qux-value' },
        ])

      it 'returns a given array without modification', ->
        array = up.util.requestDataAsArray([
          { name: 'foo-key', value: 'foo-value' },
          { name: 'bar-key', value: 'bar-value' },
        ])
        expect(array).toEqual([
          { name: 'foo-key', value: 'foo-value' },
          { name: 'bar-key', value: 'bar-value' },
        ])

      it 'does not URL-encode special characters keys or values', ->
        array = up.util.requestDataAsArray(
          'äpfel': { 'bäume': 'börse' }
        )
        expect(array).toEqual([
          { name: 'äpfel[bäume]', value: 'börse' },
        ])

      it 'does not URL-encode spaces in keys or values', ->
        array = up.util.requestDataAsArray(
          'my key': 'my value'
        )
        expect(array).toEqual([
          { name: 'my key', value: 'my value' },
        ])

      it 'does not URL-encode ampersands in keys or values', ->
        array = up.util.requestDataAsArray(
          'my&key': 'my&value'
        )
        expect(array).toEqual([
          { name: 'my&key', value: 'my&value' },
        ])

      it 'does not URL-encode equal signs in keys or values', ->
        array = up.util.requestDataAsArray(
          'my=key': 'my=value'
        )
        expect(array).toEqual([
          { name: 'my=key', value: 'my=value' },
        ])
