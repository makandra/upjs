Up.js has been renamed to Unpoly
================================

Starting with version `0.20.0` *Up.js* has been renamed to *Unpoly*.

See <https://github.com/unpoly/unpoly> for the new repository.


Migrating
---------

Pick the sections below that apply to your application.


### New Javascript and stylesheet files

The new Javascript and stylesheet assets are:

- [`unpoly.js`](https://raw.githubusercontent.com/unpoly/unpoly/master/dist/unpoly.js)
- [`unpoly.min.js`](https://raw.githubusercontent.com/unpoly/unpoly/master/dist/unpoly.min.js)
- [`unpoly.css`](https://raw.githubusercontent.com/unpoly/unpoly/master/dist/unpoly.css)
- [`unpoly.min.css`](https://raw.githubusercontent.com/unpoly/unpoly/master/dist/unpoly.min.css)

If you're using the Bootstrap integration the new assets are:

- [`unpoly-bootstrap3.js`](https://raw.githubusercontent.com/unpoly/unpoly/master/dist/unpoly-bootstrap3.js)
- [`unpoly-bootstrap3.min.js`](https://raw.githubusercontent.com/unpoly/unpoly/master/dist/unpoly-bootstrap3.min.js)
- [`unpoly-bootstrap3.css`](https://raw.githubusercontent.com/unpoly/unpoly/master/dist/unpoly-bootstrap3.css)
- [`unpoly-bootstrap3.min.css`](https://raw.githubusercontent.com/unpoly/unpoly/master/dist/unpoly-bootstrap3.min.css)


### Rubygem dependency

If you're using the Rails bindings, open your `Gemfile` and change ...

```
gem 'upjs-rails'
```

... to

```
gem 'unpoly-rails'
```

Then run `bundle install`.


### Bower package

The Bower package has been renamed from `upjs` to `unpoly`.


### Javascript API

All functions remain in the `up` namespace, so e.g. `up.replace` is still called `up.replace`.


### Unobtrusive HTML attributes

All UJS functionality remains unchanged, so e.g. `up-target` is still called `up-target`.



