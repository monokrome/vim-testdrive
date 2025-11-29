" Jest provider for vim-testdrive

function! testdrive#test_providers#jest#detect()
  " Check for jest config files
  if !empty(findfile('jest.config.js', '.;'))
    return 1
  endif
  if !empty(findfile('jest.config.ts', '.;'))
    return 1
  endif
  if !empty(findfile('jest.config.mjs', '.;'))
    return 1
  endif
  if !empty(findfile('jest.config.json', '.;'))
    return 1
  endif
  " Check package.json for jest config
  let pkg = findfile('package.json', '.;')
  if !empty(pkg)
    try
      let content = join(readfile(pkg), "\n")
      if content =~# '"jest"' || content =~# '"test":\s*"jest'
        return 1
      endif
    catch
    endtry
  endif
  " Check if jest is installed
  if !empty(finddir('node_modules/jest', '.;'))
    return 1
  endif
  return 0
endfunction

function! testdrive#test_providers#jest#get_command()
  " Use npx to run local jest
  return 'npx jest --no-coverage'
endfunction

function! testdrive#test_providers#jest#get_command_all(target)
  return 'npx jest --no-coverage'
endfunction

function! testdrive#test_providers#jest#get_command_file(file)
  return 'npx jest --no-coverage ' . shellescape(a:file)
endfunction

function! testdrive#test_providers#jest#get_command_nearest(context)
  let file = a:context.file
  let name = a:context.name

  if !empty(name)
    " Run specific test by name pattern
    return 'npx jest --no-coverage ' . shellescape(file) . ' -t ' . shellescape(name)
  else
    return 'npx jest --no-coverage ' . shellescape(file)
  endif
endfunction

function! testdrive#test_providers#jest#get_command_multiple(context)
  let file = a:context.file
  let names = a:context.names

  if !empty(names)
    " Jest -t supports regex, so join with |
    let pattern = join(names, '|')
    return 'npx jest --no-coverage ' . shellescape(file) . ' -t ' . shellescape(pattern)
  else
    return 'npx jest --no-coverage ' . shellescape(file)
  endif
endfunction

function! testdrive#test_providers#jest#get_errorformat()
  " Jest error format
  let fmt = ''
  " FAIL path/to/test.js
  let fmt .= '%E  ● %m,'
  " at Object.<anonymous> (path/file.js:10:20)
  let fmt .= '%C%*\\s at %*\\S (%f:%l:%c),'
  let fmt .= '%C%*\\s at %f:%l:%c,'
  " Standard error with file:line
  let fmt .= '%f:%l:%c: %m,'
  let fmt .= '%f:%l: %m,'
  " Ignore summary lines
  let fmt .= '%-G%.%#'
  return fmt
endfunction
