" Go test provider for vim-testdrive

function! testdrive#test_providers#go#detect()
  " Check for go.mod (Go modules)
  if !empty(findfile('go.mod', '.;'))
    return 1
  endif
  " Check for go.sum
  if !empty(findfile('go.sum', '.;'))
    return 1
  endif
  " Check for any .go files
  if !empty(glob('*.go')) || !empty(glob('**/*.go'))
    return 1
  endif
  return 0
endfunction

function! testdrive#test_providers#go#get_command()
  return 'go test ./...'
endfunction

function! testdrive#test_providers#go#get_command_all(target)
  return 'go test -v ./...'
endfunction

function! testdrive#test_providers#go#get_command_file(file)
  " Get the directory of the file
  let dir = fnamemodify(a:file, ':h')
  return 'go test -v ' . shellescape(dir)
endfunction

function! testdrive#test_providers#go#get_command_nearest(context)
  let file = a:context.file
  let name = a:context.name
  let dir = fnamemodify(file, ':h')

  if !empty(name)
    " Run specific test by name (Go test names start with Test)
    let test_name = name
    if name !~# '^Test'
      let test_name = 'Test' . toupper(name[0]) . name[1:]
    endif
    return 'go test -v -run ' . shellescape('^' . test_name . '$') . ' ' . shellescape(dir)
  else
    return 'go test -v ' . shellescape(dir)
  endif
endfunction

function! testdrive#test_providers#go#get_command_multiple(context)
  let file = a:context.file
  let names = a:context.names
  let dir = fnamemodify(file, ':h')

  if !empty(names)
    " Go -run supports regex, join with |
    let pattern = '^(' . join(names, '|') . ')$'
    return 'go test -v -run ' . shellescape(pattern) . ' ' . shellescape(dir)
  else
    return 'go test -v ' . shellescape(dir)
  endif
endfunction

function! testdrive#test_providers#go#get_errorformat()
  " Go test error format
  let fmt = ''
  " --- FAIL: TestName (0.00s)
  let fmt .= '%E--- FAIL: %m (%.%#),'
  " file_test.go:42: error message
  let fmt .= '%C%*\\s%f:%l: %m,'
  " panic: message
  let fmt .= '%Epanic: %m,'
  " Standard go error format
  let fmt .= '%f:%l:%c: %m,'
  let fmt .= '%f:%l: %m,'
  " Ignore other lines
  let fmt .= '%-G%.%#'
  return fmt
endfunction
