function! testdrive#test_providers#npm#detect()
  return findfile('package.json', '.;')
endfunction


function! testdrive#test_providers#npm#get_command()
  " TODO: This could potentially be more intelligent.
  return 'npm test'
endfunction
