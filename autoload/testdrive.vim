" vim-testdrive - Run tests from Vim/Neovim
" Maintainer: monokrome
" Version: 2.0

" Default providers (order matters - first match wins)
if !exists('g:testdrive#test_providers')
  let g:testdrive#test_providers = [
    \ 'testdrive#test_providers#vitest',
    \ 'testdrive#test_providers#jest',
    \ 'testdrive#test_providers#mocha',
    \ 'testdrive#test_providers#pytest',
    \ 'testdrive#test_providers#go',
    \ 'testdrive#test_providers#rust',
    \ 'testdrive#test_providers#npm',
    \ ]
endif

if !exists('g:testdrive#detect')
  let g:testdrive#detect = 1
endif

if !exists('g:testdrive#use_dispatch')
  let g:testdrive#use_dispatch = 1
endif

if !exists('g:loaded_dispatch')
  let g:testdrive#use_dispatch = 0
endif

if !exists('g:testdrive#always_open_results')
  let g:testdrive#always_open_results = 1
endif

" Store last test command for :TestLast
let s:last_test_cmd = ''
let s:last_test_provider = ''

" Detect which test provider to use
function! s:detect_test_provider()
  for provider in g:testdrive#test_providers
    try
      let result = function(provider.'#detect')()
      if !empty(result)
        return provider
      endif
    catch
      " Provider doesn't exist or failed, skip it
      continue
    endtry
  endfor
  return ''
endfunction

" Get test command from provider
function! s:get_test_command(provider, scope, target)
  if empty(a:provider)
    return ''
  endif

  " Check if provider supports scoped testing
  let scoped_func = a:provider . '#get_command_' . a:scope
  if exists('*' . scoped_func)
    return function(scoped_func)(a:target)
  endif

  " Fall back to basic command
  return function(a:provider . '#get_command')()
endfunction

" Get errorformat from provider
function! s:get_test_errorformat(provider)
  if empty(a:provider)
    return ''
  endif

  let formatter = a:provider . '#get_errorformat'
  if exists('*' . formatter)
    return function(formatter)()
  endif

  return ''
endfunction

" Execute test command
function! s:run_test(cmd, provider)
  if empty(a:cmd)
    echohl ErrorMsg
    echom 'testdrive: No test command to run'
    echohl None
    return
  endif

  " Store for :TestLast
  let s:last_test_cmd = a:cmd
  let s:last_test_provider = a:provider

  " Save and set errorformat
  let l:old_errorformat = &errorformat
  let l:new_errorformat = s:get_test_errorformat(a:provider)
  if !empty(l:new_errorformat)
    let &errorformat = l:new_errorformat
  endif

  echom 'testdrive: Running ' . a:cmd

  if g:testdrive#use_dispatch == 1
    let dispatch_suffix = ''
    if !g:testdrive#always_open_results
      let dispatch_suffix = '!'
    endif
    execute 'Dispatch' . dispatch_suffix . ' ' . a:cmd
  else
    " Run synchronously and populate quickfix
    let l:output = system(a:cmd)
    cexpr l:output
    if g:testdrive#always_open_results
      cwindow
    endif
  endif

  " Restore errorformat
  let &errorformat = l:old_errorformat
endfunction

" Main entry point - run all tests
function! testdrive#test()
  if exists('g:testdrive#test_provider')
    " Manual override
    call s:run_test(g:testdrive#test_provider, '')
    return
  endif

  let provider = s:detect_test_provider()
  if empty(provider)
    echohl ErrorMsg
    echom 'testdrive: Could not detect test framework. Set g:testdrive#test_provider manually.'
    echohl None
    return
  endif

  let cmd = s:get_test_command(provider, 'all', '')
  call s:run_test(cmd, provider)
endfunction

" Run tests for current file only
function! testdrive#test_file()
  if exists('g:testdrive#test_provider')
    echohl WarningMsg
    echom 'testdrive: Cannot use :TestFile with manual g:testdrive#test_provider'
    echohl None
    return
  endif

  let provider = s:detect_test_provider()
  if empty(provider)
    echohl ErrorMsg
    echom 'testdrive: Could not detect test framework.'
    echohl None
    return
  endif

  let file = expand('%:p')
  let cmd = s:get_test_command(provider, 'file', file)

  if empty(cmd)
    " Fallback: append file to base command
    let base_cmd = s:get_test_command(provider, 'all', '')
    let cmd = base_cmd . ' ' . shellescape(file)
  endif

  call s:run_test(cmd, provider)
endfunction

" Run nearest test to cursor
function! testdrive#test_nearest()
  if exists('g:testdrive#test_provider')
    echohl WarningMsg
    echom 'testdrive: Cannot use :TestNearest with manual g:testdrive#test_provider'
    echohl None
    return
  endif

  let provider = s:detect_test_provider()
  if empty(provider)
    echohl ErrorMsg
    echom 'testdrive: Could not detect test framework.'
    echohl None
    return
  endif

  let file = expand('%:p')
  let line = line('.')
  let test_name = s:find_nearest_test()

  let cmd = s:get_test_command(provider, 'nearest', {
    \ 'file': file,
    \ 'line': line,
    \ 'name': test_name,
    \ })

  if empty(cmd)
    " Fallback to file
    call testdrive#test_file()
    return
  endif

  call s:run_test(cmd, provider)
endfunction

" Run the last test command again
function! testdrive#test_last()
  if empty(s:last_test_cmd)
    echohl WarningMsg
    echom 'testdrive: No previous test to run'
    echohl None
    return
  endif

  call s:run_test(s:last_test_cmd, s:last_test_provider)
endfunction

" Run tests for visually selected range
function! testdrive#test_visual(line1, line2)
  if exists('g:testdrive#test_provider')
    echohl WarningMsg
    echom 'testdrive: Cannot use :TestVisual with manual g:testdrive#test_provider'
    echohl None
    return
  endif

  let provider = s:detect_test_provider()
  if empty(provider)
    echohl ErrorMsg
    echom 'testdrive: Could not detect test framework.'
    echohl None
    return
  endif

  let file = expand('%:p')
  let test_names = s:find_tests_in_range(a:line1, a:line2)

  if empty(test_names)
    echohl WarningMsg
    echom 'testdrive: No test functions found in selection'
    echohl None
    return
  endif

  let cmd = s:get_test_command(provider, 'multiple', {
    \ 'file': file,
    \ 'names': test_names,
    \ })

  if empty(cmd)
    " Fallback: try to build command from nearest with OR pattern
    let cmd = s:get_test_command(provider, 'nearest', {
      \ 'file': file,
      \ 'line': a:line1,
      \ 'name': join(test_names, '|'),
      \ })
  endif

  if empty(cmd)
    echohl WarningMsg
    echom 'testdrive: Provider does not support multiple test selection'
    echohl None
    return
  endif

  call s:run_test(cmd, provider)
endfunction

" Find all test functions within a line range
function! s:find_tests_in_range(line1, line2)
  let l:tests = []
  let l:patterns = [
    \ '\v^\s*def\s+(test_\w+)',
    \ '\v^\s*async\s+def\s+(test_\w+)',
    \ '\v^\s*func\s+(Test\w+)',
    \ '\v^\s*fn\s+(test_\w+)',
    \ '\v^\s*it\([''"]([^''"]+)[''"]',
    \ '\v^\s*test\([''"]([^''"]+)[''"]',
    \ '\v^\s*(it|test|describe)\([''"]([^''"]+)[''"]',
    \ ]

  for lnum in range(a:line1, a:line2)
    let line = getline(lnum)
    for pattern in l:patterns
      let match = matchlist(line, pattern)
      if !empty(match)
        " Find the captured test name (first non-empty capture group)
        for i in range(1, len(match) - 1)
          if !empty(match[i]) && match[i] !~# '^\(it\|test\|describe\)$'
            if index(l:tests, match[i]) == -1
              call add(l:tests, match[i])
            endif
            break
          endif
        endfor
      endif
    endfor
  endfor

  return l:tests
endfunction

" Find the nearest test function/method name
function! s:find_nearest_test()
  let l:line = line('.')
  let l:col = col('.')

  " Patterns for common test definitions
  let l:patterns = [
    \ '\v^\s*(def|function|func|fn|it|test|describe)\s+[''"]?(\w+)',
    \ '\v^\s*(async\s+)?(def|function)\s+test_(\w+)',
    \ '\v^\s*def\s+(test_\w+)',
    \ '\v^\s*func\s+(Test\w+)',
    \ '\v^\s*fn\s+(test_\w+)',
    \ '\v^\s*it\([''"](.+)[''"]',
    \ '\v^\s*test\([''"](.+)[''"]',
    \ ]

  " Search backwards for test definition
  for pattern in l:patterns
    let l:found = search(pattern, 'bnW')
    if l:found > 0
      let l:match = matchlist(getline(l:found), pattern)
      if !empty(l:match) && len(l:match) > 1
        " Return the captured test name
        for i in range(1, len(l:match) - 1)
          if !empty(l:match[i]) && l:match[i] !~# '^\(def\|function\|func\|fn\|it\|test\|describe\|async\)$'
            call cursor(l:line, l:col)
            return l:match[i]
          endif
        endfor
      endif
    endif
  endfor

  call cursor(l:line, l:col)
  return ''
endfunction
