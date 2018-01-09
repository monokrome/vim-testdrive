function! testdrive#test_providers#jest#detect()
  " TODO: This could definitely be more intelligent.
  return findfile('node_modules/jest', '.;')
endfunction


function! testdrive#test_providers#jest#get_command()
  return 'jest'
endfunction

