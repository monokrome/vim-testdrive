" vim-testdrive - Run tests from Vim/Neovim
" Maintainer: monokrome
" Version: 2.0

if exists('g:loaded_testdrive') || &cp || v:version < 700
  finish
endif

let g:loaded_testdrive = 1

" Commands
command! -nargs=0 Test call testdrive#test()
command! -nargs=0 TestFile call testdrive#test_file()
command! -nargs=0 TestNearest call testdrive#test_nearest()
command! -nargs=0 TestLast call testdrive#test_last()
command! -range TestVisual call testdrive#test_visual(<line1>, <line2>)

" Convenient aliases
command! -nargs=0 TF call testdrive#test_file()
command! -nargs=0 TN call testdrive#test_nearest()
command! -nargs=0 TL call testdrive#test_last()
command! -range TV call testdrive#test_visual(<line1>, <line2>)

" Sign commands
command! -nargs=? TestCoverage call testdrive#signs#coverage(<f-args>)
command! -nargs=? TestComplexity call testdrive#signs#show_complexity(<f-args>)
command! -nargs=0 TestSignsClear call testdrive#signs#clear()
command! -nargs=0 TestSignsFromQF call testdrive#signs#from_quickfix()

" Sign aliases
command! -nargs=? TC call testdrive#signs#coverage(<f-args>)
command! -nargs=? TX call testdrive#signs#show_complexity(<f-args>)
