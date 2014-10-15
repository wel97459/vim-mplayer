" ============================================================================
" FILE: mplayer.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" Mplayer frontend of Vim.
" }}}
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


let g:mplayer#mplayer = get(g:, 'mplayer#mplayer', 'mplayer')
if has('win32')
  let g:mplayer#option = get(g:, 'mplayer#option',
        \ '-idle -quiet -slave -af equalizer=0:0:0:0:0:0:0:0:0:0 -vo direct3d')
else
  let g:mplayer#option = get(g:, 'mplayer#option',
        \ '-idle -quiet -slave -af equalizer=0:0:0:0:0:0:0:0:0:0')
endif

let s:V = vital#of('mplayer')
let s:PM = s:V.import('ProcessManager')

let s:PROCESS_NAME = 'mplayer' | lockvar s:PROCESS_NAME
let s:WAIT_TIME = 0.05 | lockvar s:WAIT_TIME
let s:EXIT_KEYCODE = char2nr('q') | lockvar s:EXIT_KEYCODE
let s:LINE_BREAK = has('win32') ? "\r\n" : "\n" | lockvar s:LINE_BREAK
let s:DUMMY_COMMAND = 'get_property __NONE__'
let s:DUMMY_PATTERN = '.*ANS_ERROR=PROPERTY_UNKNOWN' . s:LINE_BREAK
let s:INFO_COMMANDS = [
      \ 'get_time_pos', 'get_time_length', 'get_percent_pos', 'get_file_name',
      \ 'get_meta_title', 'get_meta_artist', 'get_meta_album', 'get_meta_year',
      \ 'get_meta_comment', 'get_meta_track', 'get_meta_genre',
      \ 'get_audio_codec', 'get_audio_bitrate', 'get_audio_samples',
      \ 'get_video_codec', 'get_video_bitrate', 'get_video_resolution'
      \]
let s:KEY_ACTION_DICT = {
      \ "\<Left>": 'seek -10',
      \ "\<Right>": 'seek 10',
      \ "\<Up>": 'seek 60',
      \ "\<Down>": 'seek -60'
      \}
lockvar s:DUMMY_COMMAND
lockvar s:DUMMY_PATTERN
lockvar s:INDO_COMMANDS

let s:eq_presets = {
      \ 'acoustic': '0:1:2:0:0:0:0:0:2:2',
      \ 'bass': '2.25:2.0:1.75:1.50:1.25:1.00:0.75:0.5:0.25:0',
      \ 'blues': '-1:0:2:1:0:0:0:0:-1:-3',
      \ 'classic': '0:3:3:1.5:0:0:0:0:1:1',
      \ 'country': '-1:0:0:2:2:0:0:0:3:3',
      \ 'dance': '-0.5:2:2.5:0.5:-0.5:-0.5:0:0:2:2',
      \ 'eargasmExplosion': '0.75:1.5:2.25:1.75:1.5:1.25:1.75:1:2.75:2',
      \ 'folk': '-1:0:1:0:2:0:0:0:2:0',
      \ 'grunge': '-4:0:0:-2:0:0:2:3:0:-3',
      \ 'jazz': '0:0:0:1.5:1.5:1.5:0:1:2:2',
      \ 'metal': '-4:0:0:0:0:0:3:0:3:1',
      \ 'new_age': '0:3:3:0:0:0:0:0:1:1',
      \ 'normal': '0:0:0:0:0:0:0:0:0:0',
      \ 'oldies': '-2:0:2:1:0:0:0:0:-2:-5',
      \ 'opera': '0:0:0:1.5:2:1:2.5:1:0:0',
      \ 'perfect': '0.75:1.5:2.25:1.75:1.5:1.25:1.75:2.25:2.75:2',
      \ 'rap':  '-0.5:0:1:1:-0.5:-0.5:0:0:2:3',
      \ 'reggae': '-0.5:0:0:-1.5:0:1.5:2:0:1.5:2',
      \ 'rock': '-0.5:0.5:1:1.5:-0.5:-0.5:0:0:2:2',
      \ 'speech': '-2:0:2:1:0:0:0:0:-2:-5',
      \ 'swing': '-0.5:0:0:0:1.5:1.5:0:1:2:2',
      \ 'techno': '-3:0.5:2:-0.5:-0.5:-1:0:0:2.5:2.5'
      \}
let s:SUB_ARG_DICT = {}
let s:SUB_ARG_DICT.dvdnav = sort([
      \ 'up', 'down', 'left', 'right',
      \ 'menu', 'select', 'prev', 'mouse'
      \])
let s:SUB_ARG_DICT.menu = sort(['up', 'down', 'ok', 'cancel', 'hide'])
let s:SUB_ARG_DICT.step_property = sort([
      \ 'osdlevel',
      \ 'speed', 'loop',
      \ 'chapter',
      \ 'angle',
      \ 'percent_pos', 'time_pos',
      \ 'volume', 'balance', 'mute',
      \ 'audio_delay',
      \ 'switch_audio', 'switch_angle', 'switch_title',
      \ 'capturing', 'fullscreen', 'deinterlace',
      \ 'ontop', 'rootwin',
      \ 'border', 'framedropping',
      \ 'gamma', 'brightness', 'contrast', 'saturation',
      \ 'hue', 'panscan', 'vsync',
      \ 'switch_video', 'switch_program',
      \ 'sub', 'sub_source', 'sub_file', 'sub_vob', 'sub_demux', 'sub_delay',
      \ 'sub_pos', 'sub_alignment', 'sub_visibility',
      \ 'sub_forced_only', 'sub_scale',
      \ 'tv_brightness', 'tv_contrast', 'tv_saturation', 'tv_hue',
      \ 'teletext_page', 'teletext_subpage', 'teletext_mode',
      \ 'teletext_format', 'teletext_half_page'
      \])
let s:SUB_ARG_DICT.set_property = sort(s:SUB_ARG_DICT.step_property + ['stream_pos'])
let s:SUB_ARG_DICT.get_property = sort(s:SUB_ARG_DICT.set_property + [
      \ 'pause',
      \ 'filename', 'path',
      \ 'demuxer',
      \ 'stream_start', 'stream_end', 'stream_length', 'stream_time_pos',
      \ 'chapters', 'length',
      \ 'metadata',
      \ 'audio_format', 'audio_codec', 'audio_bitrate',
      \ 'samplerate', 'channels',
      \ 'video_format', 'video_codec', 'video_bitrate',
      \ 'width', 'height', 'fps', 'aspect'
      \])
lockvar s:SUB_ARG_DICT


function! mplayer#play(...)
  if !executable(g:mplayer#mplayer)
    echoerr 'Error: Please install mplayer.'
    return
  endif
  if !s:PM.is_available()
    echoerr 'Error: vimproc is unavailable.'
    return
  endif
  call mplayer#stop()
  call s:PM.touch(s:PROCESS_NAME, g:mplayer#mplayer . ' ' . g:mplayer#option)
  call s:read()
  call s:enqueue(s:make_loadcmds(a:000))
endfunction

function! mplayer#enqueue(...)
  if !mplayer#is_playing()
    call s:PM.touch(s:PROCESS_NAME, g:mplayer#mplayer . ' ' . g:mplayer#option)
    call s:read()
  endif
  call s:enqueue(s:make_loadcmds(a:000))
endfunction

function! mplayer#stop()
  if !mplayer#is_playing() | return | endif
  call s:PM.kill(s:PROCESS_NAME)
endfunction

function! mplayer#is_playing()
  let l:status = 'dead'
  try
    let l:status = s:PM.status(s:PROCESS_NAME)
  catch
  endtry
  return l:status ==# 'inactive' || l:status ==# 'active'
endfunction

function! mplayer#next(...)
  let l:n = get(a:, 1, 1)
  call mplayer#command('pt_step ' . l:n)
  call s:read()
endfunction

function! mplayer#prev(...)
  let l:n = -get(a:, 1, 1)
  call mplayer#command('pt_step ' . l:n)
  call s:read()
endfunction

function! mplayer#command(cmd, ...)
  if !mplayer#is_playing() | return | endif
  let l:is_iconv = get(a:, 1, 0)
  call s:writeln(a:cmd)
  let l:str = l:is_iconv ? iconv(s:read(), &tenc, &enc) : s:read()
  echo substitute(l:str, "^\e[A\r\e[K", '', '')
endfunction

function! mplayer#set_seek(pos)
  let l:second = s:to_second(a:pos)
  let l:lastchar = a:pos[len(a:pos) - 1]
  if l:second != -1
    call mplayer#command('seek ' . l:second . ' 2')
  elseif l:lastchar ==# 's' || l:lastchar =~# '\d'
    call mplayer#command('seek ' . a:pos . ' 2')
  elseif l:lastchar ==# '%'
    call mplayer#command('seek ' . a:pos . ' 1')
  endif
endfunction

function! mplayer#set_speed(speed, is_scaletempo)
  if a:is_scaletempo
    call mplayer#command('af_add scaletempo')
  else
    call mplayer#command('af_del scaletempo')
  endif
  call mplayer#command('speed_set ' . a:speed)
endfunction

function! mplayer#set_equalizer(band_str)
  if has_key(s:eq_presets, a:band_str)
    call mplayer#command('af_eq_set_bands ' . s:eq_presets[a:band_str])
  else
    call mplayer#command('af_eq_set_bands ' . a:band_str)
  endif
endfunction

function! mplayer#operate_with_key()
  if !mplayer#is_playing() | return | endif
  let l:key = getchar()
  while l:key != s:EXIT_KEYCODE
    if type(l:key) == 0
      call s:PM.writeln(s:PROCESS_NAME, 'key_down_event ' . l:key)
    elseif has_key(s:KEY_ACTION_DICT, l:key)
      call s:PM.writeln(s:PROCESS_NAME, s:KEY_ACTION_DICT[l:key])
    endif
    let l:key = getchar()
  endwhile
  call s:PM.writeln(s:PROCESS_NAME, s:DUMMY_COMMAND)
  call s:read(s:WAIT_TIME)
endfunction

function! mplayer#show_file_info()
  if !mplayer#is_playing() | return | endif
  call s:PM.writeln(s:PROCESS_NAME, s:DUMMY_COMMAND)
  for l:cmd in s:INFO_COMMANDS
    call s:PM.writeln(s:PROCESS_NAME, l:cmd)
  endfor
  let l:text = substitute(iconv(s:read(), &tenc, &enc), "'", '', 'g')
  let l:answers = map(split(l:text, s:LINE_BREAK), 'substitute(v:val, "^ANS_.\\+=\\(.*\\)", "\\1", "g")')
  if len(l:answers) == 0 | return | endif
  echo '[STANDARD INFORMATION]'
  try
    echo '  posiotion: ' s:to_timestr(l:answers[0]) '/' s:to_timestr(l:answers[1]) ' (' . l:answers[2] . '%)'
    echo '  filename:  ' l:answers[3]
    echo '[META DATA]'
    echo '  title:     ' l:answers[4]
    echo '  artist:    ' l:answers[5]
    echo '  album:     ' l:answers[6]
    echo '  year:      ' l:answers[7]
    echo '  comment:   ' l:answers[8]
    echo '  track:     ' l:answers[9]
    echo '  genre:     ' l:answers[10]
    echo '[AUDIO]'
    echo '  codec:     ' l:answers[11]
    echo '  bitrate:   ' l:answers[12]
    echo '  sample:    ' l:answers[13]
    if l:answers[14] !=# '' && l:answers[15] !=# '' && l:answers[16] !=# ''
      echo '[VIDEO]'
      echo '  codec:     ' l:answers[14]
      echo '  bitrate:   ' l:answers[15]
      echo '  resolution:' l:answers[16]
    endif
  catch /^Vim\%((\a\+)\)\=:E684: /
    echon ' '
    echohl ErrorMsg
    echon '... Failed to get file information'
    echohl None
  endtry
endfunction

function! mplayer#show_cmdlist()
  if s:PM.is_available()
    echo vimproc#system(g:mplayer#mplayer . ' -input cmdlist')
  else
    echoerr 'Error: vimproc is unavailable.'
  endif
endfunction

function! mplayer#flush()
  if !mplayer#is_playing() | return | endif
  let l:r = s:PM.read(s:PROCESS_NAME, [])
  if l:r[0] != ''
    echo '[stdout]'
    echo l:r[0]
  endif
  if l:r[1] != ''
    echo '[stderr]'
    echo l:r[1]
  endif
endfunction

function! mplayer#cmd_complete(arglead, cmdline, cursorpos)
  if !exists('s:cmd_complete_cache')
    let l:cmdlist = vimproc#system(g:mplayer#mplayer . ' -input cmdlist')
    let s:cmd_complete_cache = sort(map(split(l:cmdlist, "\n"), 'split(v:val, " \\+")[0]'))
  endif
  let l:args = split(a:cmdline, '\s\+')
  let l:nargs = len(l:args)
  let l:candidates = []
  if has_key(s:SUB_ARG_DICT, l:args[-1])
    let l:candidates = s:SUB_ARG_DICT[l:args[-1]]
  elseif l:nargs == 3 && a:arglead !=# '' && has_key(s:SUB_ARG_DICT, l:args[-2])
    let l:candidates = s:SUB_ARG_DICT[l:args[-2]]
  elseif l:nargs == 1 || (l:nargs == 2 && a:arglead !=# '')
    let l:candidates = s:cmd_complete_cache
  endif
  return filter(copy(l:candidates), 'stridx(v:val, a:arglead) == 0')
endfunction

function! mplayer#step_property_complete(arglead, cmdline, cursorpos)
  return s:first_arg_complete(a:arglead, a:cmdline, copy(s:SUB_ARG_DICT.step_property))
endfunction

function! mplayer#get_property_complete(arglead, cmdline, cursorpos)
  return s:first_arg_complete(a:arglead, a:cmdline, copy(s:SUB_ARG_DICT.get_property))
endfunction

function! mplayer#set_property_complete(arglead, cmdline, cursorpos)
  return s:first_arg_complete(a:arglead, a:cmdline, copy(s:SUB_ARG_DICT.set_property))
endfunction

function! mplayer#equlizer_complete(arglead, cmdline, cursorpos)
  return s:first_arg_complete(a:arglead, a:cmdline, sort(keys(s:eq_presets)))
endfunction


function! s:enqueue(loadcmds)
  for l:cmd in a:loadcmds
    call s:writeln(l:cmd)
  endfor
  call s:read(s:WAIT_TIME)
endfunction

function! s:writeln(cmd)
  call s:PM.writeln(s:PROCESS_NAME, s:DUMMY_COMMAND)
  call s:PM.writeln(s:PROCESS_NAME, a:cmd)
endfunction

function! s:read(...)
  let l:wait_time = get(a:, 1, 0.05)
  let l:pattern = get(a:, 2, [])
  let l:raw_text = s:PM.read_wait(s:PROCESS_NAME, l:wait_time, [])[0]
  return substitute(l:raw_text, s:DUMMY_PATTERN, '', 'g')
endfunction

function! s:make_loadcmds(args)
  let l:filelist = []
  for l:arg in a:args
    for l:item in split(expand(l:arg), "\n")
      if isdirectory(l:item)
        let l:dir_items = split(globpath(l:item, '*'), "\n")
        let l:filelist += map(filter(l:dir_items, 'filereadable(v:val)'), 's:process_file(v:val)')
      elseif l:item =~# '^\(cdda\|cddb\|dvd\|file\|ftp\|gopher\|tv\|vcd\|http\|https\)://'
        call add(l:filelist, 'loadfile ' . l:item . ' 1')
      else
        call add(l:filelist, s:process_file(expand(l:item)))
      endif
    endfor
  endfor
  return l:filelist
endfunction

function! s:process_file(file)
  return (a:file =~# '\.\(m3u\|m3u8\|pls\|wax\|wpl\|xspf\)$' ? 'loadlist ' : 'loadfile ') . a:file . ' 1'
endfunction

function! s:to_timestr(secstr)
  let l:second = str2nr(a:secstr)
  let l:dec_part = str2float(a:secstr) - l:second
  let l:hour = l:second / 3600
  let l:second = l:second % 3600
  let l:minute = l:second / 60
  let l:second = l:second % 60
  return printf('%02d:%02d:%02d.%1d', l:hour, l:minute, l:second, float2nr(l:dec_part * 10))
endfunction

function! s:to_second(timestr)
  if a:timestr =~# '^\d\+:\d\+:\d\+\(\.\d\+\)\?$'
    let parts = split(a:timestr, ':')
    return str2nr(parts[0]) * 3600 + str2nr(parts[1]) * 60 + str2nr(parts[2])
  elseif a:timestr =~# '^\d\+:\d\+\(\.\d\+\)\?$'
    let parts = split(a:timestr, ':')
    return str2nr(parts[0]) * 60 + str2nr(parts[1])
  else
    return -1
  endif
endfunction

function! s:first_arg_complete(arglead, cmdline, candidates)
  let l:nargs = len(split(a:cmdline, '\s\+'))
  if l:nargs == 1 || (l:nargs == 2 && a:arglead !=# '')
    return filter(a:candidates, 'stridx(v:val, a:arglead) == 0')
  endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
