if !exists('g:test_providers')
  let g:test_providers = []
  call add(g:test_providers, 'testdrive#providers#mocha')
  call add(g:test_providers, 'testdrive#providers#npm')
endif


if !exists('g:testdrive#detect')
  let g:testdrive#detect=1
endif


if !exists('g:testdrive#use_dispatch')
  let g:testdrive#use_dispatch=1
endif


if !exists('g:testdrive#always_open_results')
  let g:testdrive#always_open_results=1
endif


if !exists('g:test_state')
  let g:test_state=-1
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


function s:detect_test_program(provider)
  if !empty(a:provider)
    let testCommand=function(a:provider.'#get_command')()
    return testCommand
  endif
endfunction


function s:get_test_program(provider)
  if exists('g:testprg')
    return g:testprg
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
  if !g:testdrive#use_dispatch && exists('g:loaded_dispatch')
    let dispatch_suffix=''
    if !g:testdrive#always_open_results
      let dispatch_suffix='!'
    endif
    execute 'Dispatch'.dispatch_suffix.' '.prg
  elseif !empty(prg)
    let oldmakeprg=&makeprg
    let oldErrorFormat=&errorformat
    let newErrorFormat=s:get_test_errorformat(provider, prg)
    if !empty(newErrorFormat)
      let &errorformat=newErrorFormat
    endif
    " TODO: Why does shellescape break this?
    cexpr system(prg)
    let g:test_state=v:shell_error
    if g:testdrive#always_open_results
      copen
    endif
    let &errorformat=oldErrorFormat
  endif
endfunction
