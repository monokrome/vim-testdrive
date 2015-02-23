vim-testdrive
=============

This is a plugin providing a more fluid testing workflow from within Vim.

Vim testdrive allows you to run your tests from inside of Vim. It implements an
interface for defining test *providers* which can tell testdrive which commands
to run and how to display them in Vim's [quickfix][qf] window.

Usage
-----

You can use the `:Test` command to run tests if any provider(s) are able to run
tests for your project. The [provider API][prvdr] is very simple to get started
with in that case that current providers aren't available for your tools.

Currently, the plugin ships with simple support for running tests using the
following testing tools:

- [mocha][mca] implemented [here][mochapvdr]
- [npm][npm] implemented [here][npmpvdr]
- [nose][nose] implemented [here][nosepvdr]

Mocha support will currently only work if you have a file in `test/mocha.opts`.

Settings
--------

#### g:testdrive#testprg

Can be set to any test command, which will then be used by :Test. If non-empty,
providers will be ignored. For example, you could add this to your vimrc if you
wanted to explicitly define a test command:

```VimL
let g:testdrive#testprg='./manage.py test'
```

#### g:testdrive#detect

If set to 1 then providers will be asked to detect whether or not they are
applicable for running tests. If set to 0 then testdrive will not use the
detect() function on providers. Instead, it is expected that `g:testprg` will
be set manually to the appropriate test program.

#### g:testdrive#use_dispatch

Tests will be run via `:Dispatch` if this is set to 1. It will be automatically
reset to 0 when Vim starts up if [vim-dispatch][dsptch] is not installed. This
is set to 0 my default, because [vim-dispatch][dsptch] will end up overwriting
the `errorformat` requested by test providers. Tests runs will still work if
this is enabled, but the quickfix will not always be parsed properly - even
when a provider sets it's own `errorformat`.

#### g:testdrive#always_open_results

If set to 0, then testdrive won't automatically open the quickfix window after
tests finished executing. This is set to 1 by default.

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

A provider is expected to define a `get_command` function which will be called
after the provider detects that it is useful. The `get_command` is expected to
return a shell command that will be executed in order to run tests. For
instance, the [mocha provider][mochapvdr] currently returns 'mocha test'. This
is a function for the case where more complicated steps maybe be necessary, but
returning a string will most likely meet 99% of needs. The `get_command`
function accepts no arguments.

Optionally, a provider can also define a `get_errorformat` function. The
`get_errorformat` function accepts one argument. The argument will be the result
from the `get_command` call for the test being run. When this function is
called, the provider is expected to either update the [errorformat][efm], or to
return a string to be used for the [errorformat][efm] value. After running
tests, the [errorformat][efm] will be automatically restored to the original
value by testdrive.

The last step is to register your provider with testdrive after defining it's
module. This can be done by adding it to the `g:testdrive#test_providers`
variable. The variable is expected to be a [list][lists] of provider modules.

The ordering of items in this list matters, because the first provider which
returns a non-empty value from it's `detect` function will be used to run
further tests.

By default, it is something like this:

```VimL
let g:testdrive#test_providers = [
    \   'testdrive#providers#mocha',
    \   'testdrive#providers#npm',
    \ ]
```

If your plugin provided an autoload module called `example#testdrive#provider`
then you could add it to the list from your plugin like so:

```VimL
call add(g:testdrive#test_providers, 'example#testdrive#provider')
```

The name of your module does not matter as long as it defines the expected
functions. So, the module might look something like this in the most simple
case possible:

```VimL
function example#testdrive#provider#detect()
  return 1
endfunction


function example#testdrive#provider#get_command()
  return 'ls'
endfunction
```

This provider will always be used unless a previous provider succeeded in
`detect`. When this provider executes, it will run the command `ls` and then
send the resulting output into Vim's [quickfix][qf] window.


[mca]: http://visionmedia.github.io/mocha/
[npm]: http://npmjs.org
[nose]: https://github.com/nose-devs/nose
[qf]: http://vimhelp.appspot.com/quickfix.txt.html#quickfix
[efm]: http://vimhelp.appspot.com/options.txt.html#%27errorformat%27
[prvdr]: https://github.com/monokrome/vim-testdrive#providers
[npmpvdr]: https://github.com/monokrome/vim-testdrive/blob/master/autoload/testdrive/providers/npm.vim
[mochapvdr]: https://github.com/monokrome/vim-testdrive/blob/master/autoload/testdrive/providers/mocha.vim
[nosepvdr]: https://github.com/monokrome/vim-testdrive/blob/master/autoload/testdrive/providers/nose.vim
[dsptch]: https://github.com/tpope/vim-dispatch
[fndfl]: http://vimhelp.appspot.com/eval.txt.html#findfile%28%29
[lists]: http://vimhelp.appspot.com/eval.txt.html#Lists
