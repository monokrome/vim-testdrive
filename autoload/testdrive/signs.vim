" vim-testdrive signs - visual indicators for test status
" Maintainer: monokrome

" Sign definitions
let s:signs_defined = 0

" Configurable sign symbols
let g:testdrive_sign_pass = get(g:, 'testdrive_sign_pass', '✓')
let g:testdrive_sign_fail = get(g:, 'testdrive_sign_fail', '✗')
let g:testdrive_sign_covered = get(g:, 'testdrive_sign_covered', '●')
let g:testdrive_sign_uncovered = get(g:, 'testdrive_sign_uncovered', '○')
let g:testdrive_sign_partial = get(g:, 'testdrive_sign_partial', '◐')
let g:testdrive_sign_complex = get(g:, 'testdrive_sign_complex', '⚠')
let g:testdrive_sign_deep = get(g:, 'testdrive_sign_deep', '⛔')

function! testdrive#signs#define()
  if s:signs_defined
    return
  endif

  " Define explicit highlight groups (blue/red for colorblind accessibility)
  " Using 256-color codes for consistency across colorschemes
  " Users can override with: highlight TestdrivePass ctermfg=... guifg=...
  highlight default TestdrivePass ctermfg=33 guifg=#2196F3
  highlight default TestdriveFail ctermfg=160 guifg=#F44336
  highlight default TestdriveCovered ctermfg=33 guifg=#2196F3
  highlight default TestdriveUncovered ctermfg=160 guifg=#F44336
  highlight default TestdrivePartial ctermfg=208 guifg=#FF9800
  highlight default TestdriveComplex ctermfg=208 guifg=#FF9800
  highlight default TestdriveDeep ctermfg=160 guifg=#F44336

  " Test failure signs
  execute 'sign define testdrive_fail text=' . g:testdrive_sign_fail . ' texthl=TestdriveFail linehl=DiffDelete'
  execute 'sign define testdrive_pass text=' . g:testdrive_sign_pass . ' texthl=TestdrivePass linehl=DiffText'

  " Coverage signs (using distinct shapes for colorblind accessibility)
  execute 'sign define testdrive_covered text=' . g:testdrive_sign_covered . ' texthl=TestdriveCovered'
  execute 'sign define testdrive_uncovered text=' . g:testdrive_sign_uncovered . ' texthl=TestdriveUncovered'
  execute 'sign define testdrive_partial text=' . g:testdrive_sign_partial . ' texthl=TestdrivePartial'

  " Test quality signs (for detecting over-complex tests)
  execute 'sign define testdrive_complex text=' . g:testdrive_sign_complex . ' texthl=TestdriveComplex linehl=DiffChange'
  execute 'sign define testdrive_deep text=' . g:testdrive_sign_deep . ' texthl=TestdriveDeep linehl=DiffDelete'

  let s:signs_defined = 1
endfunction

" Clear all testdrive signs
function! testdrive#signs#clear()
  sign unplace * group=testdrive
endfunction

" Clear signs in specific buffer
function! testdrive#signs#clear_buffer(bufnr)
  execute 'sign unplace * group=testdrive buffer=' . a:bufnr
endfunction

" Place a sign
function! testdrive#signs#place(name, file, line)
  call testdrive#signs#define()

  let bufnr = bufnr(a:file)
  if bufnr == -1
    " File not loaded, try to get buffer by name
    let bufnr = bufnr(a:file, 1)
  endif

  if bufnr != -1
    execute 'sign place ' . a:line . ' line=' . a:line . ' name=testdrive_' . a:name . ' group=testdrive buffer=' . bufnr
  endif
endfunction

" Update signs from quickfix list (for test failures)
function! testdrive#signs#from_quickfix()
  call testdrive#signs#define()
  call testdrive#signs#clear()

  let qflist = getqflist()
  let files_with_errors = {}

  for item in qflist
    if item.valid && item.lnum > 0
      let file = bufname(item.bufnr)
      if !empty(file)
        if !has_key(files_with_errors, file)
          let files_with_errors[file] = []
        endif
        call add(files_with_errors[file], item.lnum)
        call testdrive#signs#place('fail', file, item.lnum)
      endif
    endif
  endfor

  return files_with_errors
endfunction

" Parse and display coverage from various formats
function! testdrive#signs#coverage(...)
  let file = a:0 > 0 ? a:1 : ''

  call testdrive#signs#define()

  " Try to find and parse coverage file
  let coverage_data = {}

  " Try Istanbul/nyc (JavaScript)
  let istanbul = findfile('coverage/coverage-final.json', '.;')
  if !empty(istanbul)
    let coverage_data = testdrive#signs#parse_istanbul(istanbul)
  endif

  " Try coverage.py (Python)
  if empty(coverage_data)
    let coveragepy = findfile('.coverage', '.;')
    if empty(coveragepy)
      let coveragepy = findfile('coverage.json', '.;')
    endif
    if !empty(coveragepy)
      let coverage_data = testdrive#signs#parse_coveragepy(coveragepy)
    endif
  endif

  " Try lcov (generic)
  if empty(coverage_data)
    let lcov = findfile('coverage/lcov.info', '.;')
    if empty(lcov)
      let lcov = findfile('lcov.info', '.;')
    endif
    if !empty(lcov)
      let coverage_data = testdrive#signs#parse_lcov(lcov)
    endif
  endif

  " Try Go coverage
  if empty(coverage_data)
    let gocover = findfile('cover.out', '.;')
    if !empty(gocover)
      let coverage_data = testdrive#signs#parse_gocover(gocover)
    endif
  endif

  if empty(coverage_data)
    echohl WarningMsg
    echom 'testdrive: No coverage data found'
    echohl None
    return
  endif

  " Place signs
  call testdrive#signs#clear()

  for [filepath, lines] in items(coverage_data)
    " If specific file requested, skip others
    if !empty(file) && filepath !~# file
      continue
    endif

    for [lnum, covered] in items(lines)
      if covered
        call testdrive#signs#place('covered', filepath, lnum)
      else
        call testdrive#signs#place('uncovered', filepath, lnum)
      endif
    endfor
  endfor

  echom 'testdrive: Coverage signs placed'
endfunction

" Parse Istanbul/nyc coverage-final.json
function! testdrive#signs#parse_istanbul(file)
  let coverage = {}

  try
    let content = join(readfile(a:file), '')
    " Basic JSON parsing for coverage data
    " Format: { "filepath": { "s": { "1": 1, "2": 0 }, "statementMap": { "1": { "start": { "line": 5 } } } } }

    " This is simplified - real implementation would use json_decode
    if has('nvim') || has('patch-8.0.0')
      let data = json_decode(content)
      for [filepath, filedata] in items(data)
        let coverage[filepath] = {}
        if has_key(filedata, 's') && has_key(filedata, 'statementMap')
          for [stmt_id, count] in items(filedata.s)
            if has_key(filedata.statementMap, stmt_id)
              let line = filedata.statementMap[stmt_id].start.line
              let coverage[filepath][line] = count > 0
            endif
          endfor
        endif
      endfor
    endif
  catch
    " Failed to parse
  endtry

  return coverage
endfunction

" Parse coverage.py JSON output
function! testdrive#signs#parse_coveragepy(file)
  let coverage = {}

  " coverage.py can output JSON with: coverage json
  if a:file =~# '\.json$'
    try
      let content = join(readfile(a:file), '')
      if has('nvim') || has('patch-8.0.0')
        let data = json_decode(content)
        if has_key(data, 'files')
          for [filepath, filedata] in items(data.files)
            let coverage[filepath] = {}
            if has_key(filedata, 'executed_lines')
              for lnum in filedata.executed_lines
                let coverage[filepath][lnum] = 1
              endfor
            endif
            if has_key(filedata, 'missing_lines')
              for lnum in filedata.missing_lines
                let coverage[filepath][lnum] = 0
              endfor
            endif
          endfor
        endif
      endif
    catch
    endtry
  endif

  return coverage
endfunction

" Parse lcov.info format
function! testdrive#signs#parse_lcov(file)
  let coverage = {}
  let current_file = ''

  try
    let lines = readfile(a:file)
    for line in lines
      if line =~# '^SF:'
        let current_file = substitute(line, '^SF:', '', '')
        let coverage[current_file] = {}
      elseif line =~# '^DA:' && !empty(current_file)
        " DA:line,hitcount
        let parts = split(substitute(line, '^DA:', '', ''), ',')
        if len(parts) >= 2
          let lnum = str2nr(parts[0])
          let hits = str2nr(parts[1])
          let coverage[current_file][lnum] = hits > 0
        endif
      elseif line =~# '^end_of_record'
        let current_file = ''
      endif
    endfor
  catch
  endtry

  return coverage
endfunction

" Parse Go cover.out format
function! testdrive#signs#parse_gocover(file)
  let coverage = {}

  try
    let lines = readfile(a:file)
    for line in lines
      " Format: file.go:startline.col,endline.col numstmt count
      let match = matchlist(line, '\v^(.+):(\d+)\.\d+,(\d+)\.\d+\s+\d+\s+(\d+)')
      if !empty(match)
        let filepath = match[1]
        let startline = str2nr(match[2])
        let endline = str2nr(match[3])
        let count = str2nr(match[4])

        if !has_key(coverage, filepath)
          let coverage[filepath] = {}
        endif

        for lnum in range(startline, endline)
          let coverage[filepath][lnum] = count > 0
        endfor
      endif
    endfor
  catch
  endtry

  return coverage
endfunction

" ============================================================================
" Test Complexity Detection
" ============================================================================

" Configuration for complexity thresholds
let g:testdrive_complexity_warn = get(g:, 'testdrive_complexity_warn', 5)
let g:testdrive_complexity_error = get(g:, 'testdrive_complexity_error', 10)

" Patterns that indicate assertions/expectations (by language)
let s:assertion_patterns = {
      \ 'python': [
      \   '\<assert\>',
      \   '\.assert',
      \   '\<assertEqual\>',
      \   '\<assertTrue\>',
      \   '\<assertFalse\>',
      \   '\<assertIn\>',
      \   '\<assertRaises\>',
      \   '\<pytest\.raises\>',
      \   '\<expect\>',
      \ ],
      \ 'javascript': [
      \   '\<expect\>',
      \   '\<assert\>',
      \   '\.toBe\>',
      \   '\.toEqual\>',
      \   '\.toMatch\>',
      \   '\.toThrow\>',
      \   '\.toHaveBeenCalled\>',
      \   '\.should\>',
      \ ],
      \ 'typescript': [
      \   '\<expect\>',
      \   '\<assert\>',
      \   '\.toBe\>',
      \   '\.toEqual\>',
      \   '\.toMatch\>',
      \   '\.toThrow\>',
      \   '\.toHaveBeenCalled\>',
      \ ],
      \ 'go': [
      \   '\<assert\.',
      \   '\<require\.',
      \   '\.Equal\>',
      \   '\.NoError\>',
      \   '\.Error\>',
      \   '\.True\>',
      \   '\.False\>',
      \   '\<t\.Error\>',
      \   '\<t\.Fatal\>',
      \ ],
      \ 'rust': [
      \   '\<assert!\>',
      \   '\<assert_eq!\>',
      \   '\<assert_ne!\>',
      \   '\<panic!\>',
      \   '\.unwrap()',
      \   '\.expect(',
      \ ],
      \ }

" Patterns that indicate mocking (by language)
let s:mock_patterns = {
      \ 'python': [
      \   '\<mock\>',
      \   '\<Mock\>',
      \   '\<MagicMock\>',
      \   '\<patch\>',
      \   '@patch',
      \   '\<mocker\>',
      \ ],
      \ 'javascript': [
      \   '\<jest\.fn\>',
      \   '\<jest\.mock\>',
      \   '\<jest\.spyOn\>',
      \   '\<sinon\.',
      \   '\<mock\>',
      \   '\<stub\>',
      \ ],
      \ 'typescript': [
      \   '\<jest\.fn\>',
      \   '\<jest\.mock\>',
      \   '\<jest\.spyOn\>',
      \   '\<vi\.fn\>',
      \   '\<vi\.mock\>',
      \   '\<vi\.spyOn\>',
      \ ],
      \ 'go': [
      \   '\<mock\.',
      \   '\<Mock\>',
      \   '\<gomock\>',
      \   '\<testify/mock\>',
      \ ],
      \ 'rust': [
      \   '\<mockall\>',
      \   '\<mock!\>',
      \ ],
      \ }

" Analyze current buffer for test complexity
function! testdrive#signs#analyze_complexity(...)
  let file = a:0 > 0 ? a:1 : expand('%')
  let bufnr = bufnr(file)

  if bufnr == -1
    return {}
  endif

  call testdrive#signs#define()

  " Determine language
  let ft = getbufvar(bufnr, '&filetype')
  if empty(ft)
    let ft = s:detect_filetype(file)
  endif

  let assertions = get(s:assertion_patterns, ft, s:assertion_patterns.python)
  let mocks = get(s:mock_patterns, ft, s:mock_patterns.python)

  " Get test boundaries
  let tests = s:find_test_boundaries(bufnr, ft)
  let results = {}

  for test in tests
    let test_name = test.name
    let start_line = test.start
    let end_line = test.end

    let assertion_count = 0
    let mock_count = 0

    " Count assertions and mocks within test
    let lines = getbufline(bufnr, start_line, end_line)
    for line in lines
      for pattern in assertions
        if line =~# pattern
          let assertion_count += 1
        endif
      endfor
      for pattern in mocks
        if line =~# pattern
          let mock_count += 1
        endif
      endfor
    endfor

    let complexity = assertion_count + mock_count
    let results[start_line] = {
          \ 'name': test_name,
          \ 'assertions': assertion_count,
          \ 'mocks': mock_count,
          \ 'complexity': complexity,
          \ }
  endfor

  return results
endfunction

" Find test function boundaries
function! s:find_test_boundaries(bufnr, ft)
  let tests = []
  let lines = getbufline(a:bufnr, 1, '$')
  let total_lines = len(lines)

  let i = 0
  while i < total_lines
    let line = lines[i]
    let test_match = s:is_test_definition(line, a:ft)

    if !empty(test_match)
      let start_line = i + 1
      let test_name = test_match
      let end_line = s:find_function_end(lines, i, a:ft)

      call add(tests, {
            \ 'name': test_name,
            \ 'start': start_line,
            \ 'end': end_line,
            \ })

      let i = end_line
    endif

    let i += 1
  endwhile

  return tests
endfunction

" Check if line is a test definition, return test name or empty
function! s:is_test_definition(line, ft)
  if a:ft ==# 'python'
    let match = matchstr(a:line, '\v^\s*(async\s+)?def\s+(test_\w+)')
    if !empty(match)
      return matchstr(a:line, '\v(test_\w+)')
    endif
  elseif a:ft ==# 'javascript' || a:ft ==# 'typescript'
    " it('...'), test('...'), describe('...')
    let match = matchstr(a:line, '\v(it|test|describe)\s*\(\s*[''"]([^''"]+)')
    if !empty(match)
      return matchstr(match, '\v[''"]([^''"]+)[''"]')
    endif
  elseif a:ft ==# 'go'
    let match = matchstr(a:line, '\vfunc\s+(Test\w+)')
    if !empty(match)
      return matchstr(match, '\vTest\w+')
    endif
  elseif a:ft ==# 'rust'
    " #[test] on previous line handled separately
    let match = matchstr(a:line, '\vfn\s+(test_\w+)')
    if !empty(match)
      return matchstr(match, '\vtest_\w+')
    endif
  endif
  return ''
endfunction

" Find the end of a function/test block
function! s:find_function_end(lines, start_idx, ft)
  let total = len(a:lines)
  let depth = 0
  let started = 0

  for i in range(a:start_idx, total - 1)
    let line = a:lines[i]

    if a:ft ==# 'python'
      " Python: track indentation
      if !started && line =~# ':\s*$'
        let started = 1
        let base_indent = len(matchstr(line, '^\s*'))
        continue
      endif
      if started
        let current_indent = len(matchstr(line, '^\s*'))
        if line !~# '^\s*$' && current_indent <= base_indent
          return i
        endif
      endif
    else
      " Brace-based languages
      let depth += len(substitute(line, '[^{]', '', 'g'))
      let depth -= len(substitute(line, '[^}]', '', 'g'))

      if line =~# '{'
        let started = 1
      endif

      if started && depth <= 0
        return i + 1
      endif
    endif
  endfor

  return total
endfunction

" Detect filetype from filename
function! s:detect_filetype(file)
  let ext = fnamemodify(a:file, ':e')
  let map = {
        \ 'py': 'python',
        \ 'js': 'javascript',
        \ 'ts': 'typescript',
        \ 'tsx': 'typescript',
        \ 'jsx': 'javascript',
        \ 'go': 'go',
        \ 'rs': 'rust',
        \ }
  return get(map, ext, 'python')
endfunction

" Place complexity signs in current buffer
function! testdrive#signs#show_complexity(...)
  let file = a:0 > 0 ? a:1 : expand('%')

  call testdrive#signs#define()

  " Clear existing complexity signs first
  call s:clear_complexity_signs(file)

  let analysis = testdrive#signs#analyze_complexity(file)

  if empty(analysis)
    echohl WarningMsg
    echom 'testdrive: No tests found in file'
    echohl None
    return
  endif

  let warn_threshold = g:testdrive_complexity_warn
  let error_threshold = g:testdrive_complexity_error
  let complex_tests = []

  for [lnum, data] in items(analysis)
    if data.complexity >= error_threshold
      call testdrive#signs#place('deep', file, lnum)
      call add(complex_tests, data.name . ' (' . data.complexity . ' items: ' . data.assertions . ' asserts, ' . data.mocks . ' mocks)')
    elseif data.complexity >= warn_threshold
      call testdrive#signs#place('complex', file, lnum)
      call add(complex_tests, data.name . ' (' . data.complexity . ' items)')
    endif
  endfor

  if empty(complex_tests)
    echom 'testdrive: All tests have reasonable complexity'
  else
    echohl WarningMsg
    echom 'testdrive: Found ' . len(complex_tests) . ' complex test(s):'
    echohl None
    for test in complex_tests
      echom '  - ' . test
    endfor
  endif
endfunction

" Clear only complexity signs
function! s:clear_complexity_signs(file)
  let bufnr = bufnr(a:file)
  if bufnr != -1
    " Signs are in testdrive group, but we want to keep fail/pass/coverage
    " For now, clear all and re-place if needed
  endif
endfunction

" Combined view: show failures, coverage, and complexity
function! testdrive#signs#show_all(...)
  let file = a:0 > 0 ? a:1 : expand('%')

  call testdrive#signs#clear()
  call testdrive#signs#from_quickfix()
  call testdrive#signs#show_complexity(file)
endfunction
