" Rust/Cargo test provider for vim-testdrive

function! testdrive#test_providers#rust#detect()
  " Check for Cargo.toml
  if !empty(findfile('Cargo.toml', '.;'))
    return 1
  endif
  " Check for Cargo.lock
  if !empty(findfile('Cargo.lock', '.;'))
    return 1
  endif
  return 0
endfunction

function! testdrive#test_providers#rust#get_command()
  return 'cargo test'
endfunction

function! testdrive#test_providers#rust#get_command_all(target)
  return 'cargo test'
endfunction

function! testdrive#test_providers#rust#get_command_file(file)
  " Rust doesn't easily support file-based testing
  " Try to extract module name from file path
  let file = a:file
  let module = fnamemodify(file, ':t:r')

  " If it's a test file, run tests in that module
  if module ==# 'mod' || module ==# 'lib' || module ==# 'main'
    return 'cargo test'
  endif

  return 'cargo test ' . module . '::'
endfunction

function! testdrive#test_providers#rust#get_command_nearest(context)
  let name = a:context.name

  if !empty(name)
    " Run specific test by name
    return 'cargo test ' . shellescape(name) . ' -- --exact'
  else
    return 'cargo test'
  endif
endfunction

function! testdrive#test_providers#rust#get_command_multiple(context)
  let names = a:context.names

  if !empty(names)
    " Cargo test filter is a substring match, run each or use regex-like
    " For multiple tests, just pass the pattern (cargo will match)
    let pattern = join(names, '\|')
    return 'cargo test ' . shellescape(pattern)
  else
    return 'cargo test'
  endif
endfunction

function! testdrive#test_providers#rust#get_errorformat()
  " Rust/Cargo test error format
  let fmt = ''
  " error[E0382]: message
  let fmt .= '%Eerror[%*[^]]]:%m,'
  let fmt .= '%Eerror:%m,'
  " --> src/file.rs:10:5
  let fmt .= '%C  --> %f:%l:%c,'
  let fmt .= '%C --> %f:%l:%c,'
  " thread 'test_name' panicked at 'message', file.rs:10:5
  let fmt .= "%Ethread '%*[^']' panicked at '%m'\\, %f:%l:%c,"
  let fmt .= '%Ethread %*[^ ] panicked at %f:%l:%c:,'
  " Standard format
  let fmt .= '%f:%l:%c: %m,'
  let fmt .= '%f:%l: %m,'
  " Ignore other lines
  let fmt .= '%-G%.%#'
  return fmt
endfunction
