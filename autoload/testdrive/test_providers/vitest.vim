" Vitest provider for vim-testdrive

function! testdrive#test_providers#vitest#detect()
  " Check for vitest config files
  if !empty(findfile('vitest.config.js', '.;'))
    return 1
  endif
  if !empty(findfile('vitest.config.ts', '.;'))
    return 1
  endif
  if !empty(findfile('vitest.config.mjs', '.;'))
    return 1
  endif
  if !empty(findfile('vitest.config.mts', '.;'))
    return 1
  endif
  " Check for vite.config with test config
  let vite_config = findfile('vite.config.ts', '.;')
  if empty(vite_config)
    let vite_config = findfile('vite.config.js', '.;')
  endif
  if !empty(vite_config)
    try
      let content = join(readfile(vite_config), "\n")
      if content =~# 'test:' || content =~# 'vitest'
        return 1
      endif
    catch
    endtry
  endif
  " Check package.json
  let pkg = findfile('package.json', '.;')
  if !empty(pkg)
    try
      let content = join(readfile(pkg), "\n")
      if content =~# '"vitest"' || content =~# '"test":\s*"vitest'
        return 1
      endif
    catch
    endtry
  endif
  " Check if vitest is installed
  if !empty(finddir('node_modules/vitest', '.;'))
    return 1
  endif
  return 0
endfunction

function! testdrive#test_providers#vitest#get_command()
  return 'npx vitest run'
endfunction

function! testdrive#test_providers#vitest#get_command_all(target)
  return 'npx vitest run'
endfunction

function! testdrive#test_providers#vitest#get_command_file(file)
  return 'npx vitest run ' . shellescape(a:file)
endfunction

function! testdrive#test_providers#vitest#get_command_nearest(context)
  let file = a:context.file
  let name = a:context.name

  if !empty(name)
    return 'npx vitest run ' . shellescape(file) . ' -t ' . shellescape(name)
  else
    return 'npx vitest run ' . shellescape(file)
  endif
endfunction

function! testdrive#test_providers#vitest#get_command_multiple(context)
  let file = a:context.file
  let names = a:context.names

  if !empty(names)
    " Vitest -t supports regex like Jest
    let pattern = join(names, '|')
    return 'npx vitest run ' . shellescape(file) . ' -t ' . shellescape(pattern)
  else
    return 'npx vitest run ' . shellescape(file)
  endif
endfunction

function! testdrive#test_providers#vitest#get_errorformat()
  " Vitest error format (similar to Jest)
  let fmt = ''
  let fmt .= '%E  ⎯ Failed %m,'
  let fmt .= '%E  ✕ %m,'
  let fmt .= '%C%*\\s at %*\\S (%f:%l:%c),'
  let fmt .= '%C%*\\s at %f:%l:%c,'
  let fmt .= '%f:%l:%c: %m,'
  let fmt .= '%f:%l: %m,'
  let fmt .= '%-G%.%#'
  return fmt
endfunction
