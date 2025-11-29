" pytest provider for vim-testdrive

function! testdrive#test_providers#pytest#detect()
  " Check for pytest configuration files
  if !empty(findfile('pytest.ini', '.;'))
    return 1
  endif
  if !empty(findfile('pyproject.toml', '.;'))
    " Check if pyproject.toml has pytest config
    let pyproject = findfile('pyproject.toml', '.;')
    if !empty(pyproject)
      let content = join(readfile(pyproject), "\n")
      if content =~# '\[tool\.pytest' || content =~# '\[pytest\]'
        return 1
      endif
    endif
  endif
  if !empty(findfile('setup.cfg', '.;'))
    let setupcfg = findfile('setup.cfg', '.;')
    if !empty(setupcfg)
      let content = join(readfile(setupcfg), "\n")
      if content =~# '\[tool:pytest\]'
        return 1
      endif
    endif
  endif
  if !empty(findfile('conftest.py', '.;'))
    return 1
  endif
  " Check for test files
  if !empty(glob('test_*.py')) || !empty(glob('*_test.py'))
    return 1
  endif
  if !empty(glob('tests/*.py')) || !empty(glob('test/*.py'))
    return 1
  endif
  return 0
endfunction

function! testdrive#test_providers#pytest#get_command()
  return 'pytest --tb=short -q'
endfunction

function! testdrive#test_providers#pytest#get_command_all(target)
  return 'pytest --tb=short -q'
endfunction

function! testdrive#test_providers#pytest#get_command_file(file)
  return 'pytest --tb=short -q ' . shellescape(a:file)
endfunction

function! testdrive#test_providers#pytest#get_command_nearest(context)
  let file = a:context.file
  let name = a:context.name

  if !empty(name)
    " Run specific test by name
    return 'pytest --tb=short -q ' . shellescape(file) . ' -k ' . shellescape(name)
  else
    " Fall back to file
    return 'pytest --tb=short -q ' . shellescape(file)
  endif
endfunction

function! testdrive#test_providers#pytest#get_command_multiple(context)
  let file = a:context.file
  let names = a:context.names

  if !empty(names)
    " pytest -k supports OR with 'or' keyword or just space-separated
    let pattern = join(names, ' or ')
    return 'pytest --tb=short -q ' . shellescape(file) . ' -k ' . shellescape(pattern)
  else
    return 'pytest --tb=short -q ' . shellescape(file)
  endif
endfunction

function! testdrive#test_providers#pytest#get_errorformat()
  " pytest error format for quickfix
  let fmt = ''
  " FAILED test_file.py::test_name - AssertionError
  let fmt .= '%E%*[=] FAILURES %*[=],'
  let fmt .= '%E%*[_] %o %*[_],'
  let fmt .= '%C%f:%l: %m,'
  let fmt .= '%C%f:%l: in %o,'
  " Standard Python tracebacks
  let fmt .= '%E  File "%f"\, line %l,'
  let fmt .= '%E  File "%f"\, line %l\, in %o,'
  let fmt .= '%C    %m,'
  let fmt .= '%Z%m,'
  " Short format: file:line: message
  let fmt .= '%f:%l: %m,'
  let fmt .= '%f:%l:%c: %m,'
  " Ignore other lines
  let fmt .= '%-G%.%#'
  return fmt
endfunction
