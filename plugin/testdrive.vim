if exists('g:loaded_testdrive') || &cp || v:version < 700
  finish
endif


let g:loaded_testdrive = 1


command Test execute testdrive#test()
