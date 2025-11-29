" Nose provider for vim-testdrive
" NOTE: nose is deprecated, consider using pytest instead

function! testdrive#test_providers#nose#detect()
  " Check for nose-specific test patterns
  " (pytest is checked first in provider list, so this is fallback)
  if !empty(glob('*_tests.py'))
    return 1
  endif
  if !empty(glob('test/*_tests.py'))
    return 1
  endif
  if !empty(glob('tests/*_tests.py'))
    return 1
  endif
  " Check for .noserc config
  if !empty(findfile('.noserc', '.;'))
    return 1
  endif
  if !empty(findfile('setup.cfg', '.;'))
    let setupcfg = findfile('setup.cfg', '.;')
    try
      let content = join(readfile(setupcfg), "\n")
      if content =~# '\[nosetests\]'
        return 1
      endif
    catch
    endtry
  endif
  return 0
endfunction

function! testdrive#test_providers#nose#get_command()
  return 'nosetests'
endfunction

function! testdrive#test_providers#nose#get_command_all(target)
  return 'nosetests -v'
endfunction

function! testdrive#test_providers#nose#get_command_file(file)
  return 'nosetests -v ' . shellescape(a:file)
endfunction

function! testdrive#test_providers#nose#get_command_nearest(context)
  let file = a:context.file
  let name = a:context.name

  if !empty(name)
    " Nose uses module:TestClass.test_method format
    return 'nosetests -v ' . shellescape(file) . ':' . name
  else
    return 'nosetests -v ' . shellescape(file)
  endif
endfunction

function! testdrive#test_providers#nose#get_errorformat()
  " Nose error format
  let fmt = ''
  " Standard Python tracebacks
  let fmt .= '%E  File "%f"\, line %l,'
  let fmt .= '%E  File "%f"\, line %l\, in %o,'
  let fmt .= '%C    %m,'
  let fmt .= '%Z%m,'
  let fmt .= '%f:%l: %m,'
  let fmt .= '%-G%.%#'
  return fmt
endfunction
