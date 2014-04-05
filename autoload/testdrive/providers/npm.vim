function testdrive#providers#npm#detect()
  return findfile('package.json', '.;')
endfunction

function testdrive#providers#npm#get_command()
  return 'npm test'
endfunction
