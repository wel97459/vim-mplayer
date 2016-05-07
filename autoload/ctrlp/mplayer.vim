" ============================================================================
" FILE: mplayer.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" descriptions.
" ctrlp.vim: https://github.com/ctrlpvim/ctrlp.vim
" }}}
" ============================================================================
if exists('g:loaded_ctrlp_mplayer') && g:loaded_ctrlp_mplayer
  finish
endif
let g:loaded_ctrlp_mplayer = 1
let s:save_cpo = &cpo
set cpo&vim

let s:mplayer_vars = {
      \ 'init': 'ctrlp#mplayer#init()',
      \ 'accept': 'ctrlp#mplayer#accept',
      \ 'exit': 'ctrlp#mplayer#exit()',
      \ 'lname': 'mplayer',
      \ 'sname': 'mplayer',
      \ 'type': 'path',
      \ 'sort': 0,
      \ 'nolim': 1,
      \ 'multsel': 1,
      \ 'opmul': 1
      \}

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:mplayer_var)
else
  let g:ctrlp_ext_vars = [s:mplayer_vars]
endif

let s:candidate = []
let s:suffixes = ['mp3', 'flac', 'wav', 'm3u']

function! ctrlp#mplayer#start(...) abort
    let dir = expand(a:0 > 0 ? a:1 : get(g:, 'mplayer#default_dir', '~/'))
    if dir[-1 :] !=# '/'
        let dir .= '/'
    endif
    
    let glob_pattern = empty(g:mplayer#suffixes) ? '*' :
        \ ('*.{' . join(s:suffixes, ',') . '}')
    echom glob_pattern
    echom dir

  let s:candidate = split(
              \ globpath(dir, glob_pattern, 1) . "\n" .
              \ globpath(dir . '**', glob_pattern, 1)
              \ , '\n')
  echo s:candidate

  call ctrlp#init(ctrlp#mplayer#id())
endfunction

function! ctrlp#mplayer#init() abort
  return s:candidate
endfunction

function! ctrlp#mplayer#accept(mode, str)
  call ctrlp#exit()
"  echo [a:mode, a:str]
  cal call('mplayer#enqueue', a:str)
" call mplayer#enqueue(a:str)
endfunction

function! ctrlp#mplayer#exit() abort
  if g:mplayer#enable_ctrlp_multi_select
    autocmd MPlayer CursorHold,CursorHoldI,CursorMoved,CursorMovedI,InsertEnter * call ctrlp#mplayer#delete_autocmds_hook()
  endif
endfunction


function! ctrlp#mplayer#enqueue_hook() abort
  call mplayer#enqueue(expand('%:p'))
  bwipeout
endfunction

function! ctrlp#mplayer#delete_autocmds_hook() abort
  autocmd! MPlayer CursorHold,CursorHoldI,CursorMoved,CursorMovedI,InsertEnter *
  autocmd! MPlayer BufReadCmd
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#mplayer#id()
  return s:id
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
