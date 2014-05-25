function testdrive#providers#mocha#detect()
  " TODO: This could definitely be more intelligent.
  return findfile('test/mocha.opts', '.;')
endfunction


function testdrive#providers#mocha#get_command()
  return 'mocha test'
endfunction


function testdrive#providers#mocha#get_errorformat(cmd)
  " Case where error does have a traceback
  let &errorformat = '%E%.%#%n) %s:,'
  let &errorformat .= '%C%.%#Error: %m,'
  let &errorformat .= '%C%.%#at %s (%f:%l:%c),'
  let &errorformat .= '%Z%.%#at %s (%f:%l:%c),'
  let &errorformat .= '%-G%.%#,'
endfunction

