if !exists('g:test_providers')
  let g:test_providers = ['testdrive#providers#npm']
endif


if !exists('g:testdrive#cache_provider')
  let g:testdrive#cache_provider=1
endif


if !exists('g:testdrive#detect')
  let g:testdrive#detect=1
endif


if !exists('g:testdrive#use_dispatch')
  let g:testdrive#use_dispatch=1
endif

function s:detect_test_provider()
  for provider in g:test_providers
    let result=function(provider.'#detect')()
    if !empty(result)
      return provider
    endif
  endfor
  echom 'Could not find a test provider. Set testprg manually.'
endfunction


function s:detect_test_program()
  let provider=s:detect_test_provider()
  if !empty(provider)
    let testCommand=function(provider.'#get_command')()
    if g:testdrive#cache_provider
      let b:testprg=testCommand
    endif
    return testCommand
  endif
endfunction


function s:get_test_program()
  if exists('b:testprg')
    return b:testprg
  elseif exists('g:testprg')
    return g:testprg
  elseif g:testdrive#detect
    return s:detect_test_program()
  endif
endfunction


function testdrive#test()
  let prg=s:get_test_program()
  if g:testdrive#use_dispatch && exists('g:loaded_dispatch')
    execute 'Dispatch '.prg
  elseif !empty(prg)
    cexpr system(prg)
  endif
endfunction
