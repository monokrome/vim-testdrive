function testdrive#providers#npm#detect()
  return findfile('package.json', '.;')
endfunction


function testdrive#providers#npm#get_command()
  " TODO: This could potentially be more intelligent.
  return 'npm test'
endfunction
