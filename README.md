vim-testdrive
=============

This is a plugin providing a more fluid testing workflow from within Vim.

Vim testdrive allows you to run your tests from inside of Vim. It implements an
interface for defining test "providers" which can tell testdrive which commands
to run and how to display them in Vim's [quickfix][qf] window.

Usage
-----

You can use the `:Test` command to run tests if any provider(s) are able to run
tests for your project. The provider API is very simple to get started with in
that case that current providers aren't available for your tools.

Currently, the plugin ships with simple support for running tests using the following testing tools:

- [mocha][mca] implemented [here][mochapvdr]
- [npm][npm] implemented [here][npmpvdr]

Mocha support will currently only work if you have a file in `test/mocha.opts`.

Providers
---------

If you want to use an unsupported test framework, it should be relatively
simple to write your own test provider in VimL. A test provider is a Vim
namespace which provide functions called `detect` and `get_command`.

The detect function is expected to return a non-empty value if the project is
set up to use it's tests. For instance, the [npm provider][npmpvdr] looks up
the tree for a file called **package.json**. If the file is found, then the
filename as provided by [findfile][fndfl] is returned.  The `detect` function
accepts no arguments.

A provider is expected to define a `get_command` function which willm be called
after the provider detects that it is useful. The `get_command` is expected to
return a shell command that will be executed in order to run tests. For
instance, the [mocha provider][mochapvdr] currently returns 'mocha test'. This
is a function for the case where more complicated steps maybe be necessary, but
returning a string will most likely meet 99% of needs. The `get_command`
function accepts no arguments.

Optionally, a provider can also define a `get_errorformat` function. The
`get_errorformat` function accepts one argument. It will be the result from the
`get_command` call for the test being run.

The last step is to register your provider with testdrive after defining it's
module. This can be done by adding it to the `g:testdrive#test_providers`
variable. The variable is expected to be a [list][lists] of provider modules.

By default, it is something like this:

```VimL
let g:testdrive#test_providers = [
    \   'testdrive#providers#mocha',
    \   'testdrive#providers#npm',
    \ ]
```

If your plugin provided an autoload module called `example#testdrive#provider`
then you could add it to the list like this:

    call add(g:testdrive#test_providers, 'example#testdrive#provider')

The name of your module does not matter as long as it defines the expected
functions. So, the module might look something like this in the most simple
case possible:

```VimL
function example#testdrive#provider#detect()
  return 1
endfunction


function example#testdrive#provider#get_command()
  return 'example command here'
endfunction
```


[mca]: http://visionmedia.github.io/mocha/
[npm]: http://npmjs.org
[qf]: http://vimhelp.appspot.com/quickfix.txt.html#quickfix
[npmpvdr]: https://github.com/monokrome/vim-testdrive/blob/master/autoload/testdrive/providers/npm.vim
[mochapvdr]: https://github.com/monokrome/vim-testdrive/blob/master/autoload/testdrive/providers/mocha.vim
[fndfl]: http://vimhelp.appspot.com/eval.txt.html#findfile%28%29
[lists]: http://vimhelp.appspot.com/eval.txt.html#Lists
