function! testdrive#test_providers#pytest#detect()
  return findfile('setup.py', '.;')
endfunction


function! testdrive#test_providers#pytest#get_command()
  " TODO: This could definitely be more intelligent.
  return 'py.test'
endfunction
