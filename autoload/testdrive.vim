if !exists('g:testdrive#test_providers')
  let g:testdrive#test_providers = []
  call add(g:testdrive#test_providers, 'testdrive#providers#mocha')
  call add(g:testdrive#test_providers, 'testdrive#providers#npm')
endif


if !exists('g:testdrive#detect')
  let g:testdrive#detect=1
endif


if !exists('g:testdrive#use_dispatch')
  let g:testdrive#use_dispatch=0
endif


if !exists('g:loaded_dispatch')
  let g:testdrive#use_dispatch=0
endif


if !exists('g:testdrive#always_open_results')
  let g:testdrive#always_open_results=1
endif


function s:detect_test_provider()
  for provider in g:testdrive#test_providers
    let result=function(provider.'#detect')()
    if !empty(result)
      return provider
    endif
  endfor
  echom 'Could not find a test provider. Set g:testdrive#testprg manually.'
endfunction


function s:detect_test_program(provider)
  if !empty(a:provider)
    let testCommand=function(a:provider.'#get_command')()
    return testCommand
  endif
endfunction


function s:get_test_program(provider)
  if exists('g:testdrive#testprg')
    return g:testdrive#testprg
  elseif g:testdrive#detect
    return s:detect_test_program(a:provider)
  endif
endfunction


function s:get_test_errorformat(provider, command)
  let formatter=a:provider.'#get_errorformat'
  if exists('*'.formatter)
    return function(formatter)(a:command)
  endif
endfunction


function testdrive#test()
  let provider=s:detect_test_provider()
  let prg=s:get_test_program(provider)
  if !empty(prg)
    let oldErrorFormat=&errorformat
    let newErrorFormat=s:get_test_errorformat(provider, prg)
    if !empty(newErrorFormat)
      let &errorformat=newErrorFormat
    endif
    if g:testdrive#use_dispatch == 1
      let dispatch_suffix=''
      if !g:testdrive#always_open_results
        let dispatch_suffix='!'
      endif
      execute 'Dispatch'.dispatch_suffix.' '.prg
    else
      " TODO: Why does shellescape break this?
      cexpr system(prg)
      if g:testdrive#always_open_results
        cwindow
      endif
    endif
    let &errorformat=oldErrorFormat
  endif
endfunction

