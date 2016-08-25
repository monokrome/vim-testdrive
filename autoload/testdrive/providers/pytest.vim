function! testdrive#providers#pytest#detect()
  return findfile('setup.py', '.;')
endfunction


function! testdrive#providers#pytest#get_command()
  " TODO: This could definitely be more intelligent.
  return 'py.test'
endfunction
