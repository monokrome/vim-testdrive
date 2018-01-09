function! testdrive#test_providers#nose#detect()
    return glob('*_tests.py').glob('test/*_tests.py').glob('tests/*_tests.py')
endfunction

function! testdrive#test_providers#nose#get_command()
    return 'nosetests'
endfunction
