" NPM test provider for vim-testdrive
" This is a fallback - runs whatever is in package.json scripts.test

function! testdrive#test_providers#npm#detect()
  " Check for package.json with test script
  let pkg = findfile('package.json', '.;')
  if !empty(pkg)
    try
      let content = join(readfile(pkg), "\n")
      if content =~# '"test":'
        return 1
      endif
    catch
    endtry
  endif
  return 0
endfunction

function! testdrive#test_providers#npm#get_command()
  return 'npm test'
endfunction

function! testdrive#test_providers#npm#get_command_all(target)
  return 'npm test'
endfunction

" NPM test doesn't support file-specific testing by default
" The specific test framework provider should be used instead

function! testdrive#test_providers#npm#get_errorformat()
  " Generic Node.js error format
  let fmt = ''
  " Error: message
  let fmt .= '%EError: %m,'
  " at Object.<anonymous> (path/file.js:10:20)
  let fmt .= '%C%*\\s at %*\\S (%f:%l:%c),'
  let fmt .= '%C%*\\s at %f:%l:%c,'
  " Standard file:line format
  let fmt .= '%f:%l:%c: %m,'
  let fmt .= '%f:%l: %m,'
  " Ignore other lines
  let fmt .= '%-G%.%#'
  return fmt
endfunction
