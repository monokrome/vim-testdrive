" Mocha provider for vim-testdrive

function! testdrive#test_providers#mocha#detect()
  " Check for mocha config files
  if !empty(findfile('.mocharc.json', '.;'))
    return 1
  endif
  if !empty(findfile('.mocharc.js', '.;'))
    return 1
  endif
  if !empty(findfile('.mocharc.yaml', '.;'))
    return 1
  endif
  if !empty(findfile('.mocharc.yml', '.;'))
    return 1
  endif
  " Legacy config
  if !empty(findfile('test/mocha.opts', '.;'))
    return 1
  endif
  " Check package.json for mocha
  let pkg = findfile('package.json', '.;')
  if !empty(pkg)
    try
      let content = join(readfile(pkg), "\n")
      if content =~# '"mocha"' || content =~# '"test":\s*"mocha'
        return 1
      endif
    catch
    endtry
  endif
  " Check if mocha is installed
  if !empty(finddir('node_modules/mocha', '.;'))
    return 1
  endif
  return 0
endfunction

function! testdrive#test_providers#mocha#get_command()
  return 'npx mocha'
endfunction

function! testdrive#test_providers#mocha#get_command_all(target)
  return 'npx mocha'
endfunction

function! testdrive#test_providers#mocha#get_command_file(file)
  return 'npx mocha ' . shellescape(a:file)
endfunction

function! testdrive#test_providers#mocha#get_command_nearest(context)
  let file = a:context.file
  let name = a:context.name

  if !empty(name)
    " Run specific test by grep pattern
    return 'npx mocha ' . shellescape(file) . ' --grep ' . shellescape(name)
  else
    return 'npx mocha ' . shellescape(file)
  endif
endfunction

function! testdrive#test_providers#mocha#get_command_multiple(context)
  let file = a:context.file
  let names = a:context.names

  if !empty(names)
    " Mocha --grep supports regex
    let pattern = join(names, '|')
    return 'npx mocha ' . shellescape(file) . ' --grep ' . shellescape(pattern)
  else
    return 'npx mocha ' . shellescape(file)
  endif
endfunction

function! testdrive#test_providers#mocha#get_errorformat()
  " Mocha error format
  let fmt = ''
  " Error header: 1) test name:
  let fmt .= '%E%*[0-9]) %m:,'
  " AssertionError: message
  let fmt .= '%C%*\\s%o: %m,'
  " at Context.<anonymous> (file.js:10:20)
  let fmt .= '%C%*\\s at %*\\S (%f:%l:%c),'
  let fmt .= '%C%*\\s at %f:%l:%c,'
  let fmt .= '%Z%*\\s at %*\\S (%f:%l:%c),'
  " Standard file:line format
  let fmt .= '%f:%l:%c: %m,'
  let fmt .= '%f:%l: %m,'
  " Ignore other lines
  let fmt .= '%-G%.%#'
  return fmt
endfunction
