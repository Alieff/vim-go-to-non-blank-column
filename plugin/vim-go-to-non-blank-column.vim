" if start from non-blank, it will search next blank
" if start from blank it will search next non-blank
let g:custom_gnbc_auto_pipe_mode = 0
function! s:GotoNonBlankColumn(...) range
  " remember search state, and last search string, because we want to use it, and don't want lose user's
  let &hls=0
  let @d=v:hlsearch
  let @s=@/
  " remember intial column, case: normal & virtual"
  let init_col = col('.')
  let init_line = line('.')
  " remember intial column horizontal view
  let init_h_scroll = winsaveview().leftcol

  """
  " pipe mode: buat navigate di dalam table yg delimiternya '|'
  " left space mode: kalo mau naviagate di text yg idented by space, nanti dia
  "                  akan jump ke line yg identasinya < dari current cursor pos (column)
  """

  " check if user activate feature auto-detect for pipe mode
  if g:custom_gnbc_auto_pipe_mode == 1
    " see pipe mode definition below
    let is_pipe_mode = 0
    " see leftspace mode definition below
    let is_leftspace_mode = 0
    if getline('.') =~ '^ *|.*| *$'
      let is_pipe_mode = 1
    else
      let is_leftspace_mode = 1
    endif

    if is_pipe_mode
      " save current cell start,end position
      normal F|
      let first_pipe_loc = col('.')
      normal f|
      let next_pipe_loc = col('.')
    endif
  else
    let is_pipe_mode = 0
    let is_leftspace_mode = 1
  endif
 
  if is_leftspace_mode
    ""check is mode 'p' (backward motion)
    if len(a:000) > 1 && a:2 == 'p' 
      "get next char (backward motion) at cursor
      let next_char = getline(line('.')-1)[col('.')-1]
      let next_line = getline(line('.')-1)
    else
      "get next char (forward motion) at cursor
      let next_char = getline(line('.')+1)[col('.')-1]
      let next_line = getline(line('.')+1)
    endif
  endif

  " construct search string, according to movement modes
  if is_pipe_mode == 1
    " hollow_mode_regex: find next solid
    let hollow_mode_regex ='^.\{'.(first_pipe_loc-1).'}| *[^| ][^|]*|'

    " make sure current line doesn't count
    normal 00
    " if the next match of using hollow_mode_regex is not just one match away, use hollow_mode_regex 
    if len(a:000) > 1 && a:2 == 'p' 
      let is_hollow_mode =  (init_line - 1) != search(hollow_mode_regex,'nb')
    else
      let is_hollow_mode =  (init_line + 1) != search(hollow_mode_regex,'n')
    endif

    if is_hollow_mode
      " is_hollow_mode is for doing:  
      " | [<]text>      |
      " |               |
      " | [<]text>      |
      " (^....| *[^| ][^|]*|) 
      let @/='^.\{'.(first_pipe_loc-1).'}| *[^| ][^|]*|'
    else
      " solid mode is for doing:  
      " | [<]text>      |
      " | <text>        |
      " | [ ]           |
      " (^....| *[^| ][^|]*|) 
      let @/='^.\{'.(first_pipe_loc-1).'}| *|'
    endif
  elseif is_leftspace_mode
    " let is_hollow_mode = next_char == ' ' || len(next_line) < col('.')
    let is_hollow_mode = 1 " gw lupa hollow mmode di leftspace buat apa, didisable dulu"
    " echom 'is_hollow_mode'
    " echom is_hollow_mode
    if is_hollow_mode
      " is_hollow_mode is for doing
      "[<]text>
      "   <text>
      "[<]text>
      " disini kita mau cari line yg punya karakter non spasi (ex: a-z), sebelum current column
      let @/='^\s\{,'.(col('.')-1).'}\S'
    else
      " not is_hollow_mode is for doing
      " [<]text>
      " 
      " [<]text>
      let @/='^\s\{'.(col('.')-1).'}\s'
    endif
  endif

  " go search, according to param, p=prev / backward
  if len(a:000) > 1 && a:2 == 'p'
    try
      normal N, 
    catch /.*/
      echom "GotoNonBlankColumn: pattern not found"
    endtry
    " in case we have to press N twice
    if init_line == line('.')
      try
        normal N, 
      catch /.*/
        echom "GotoNonBlankColumn: pattern not found"
      endtry
    endif
  else
    try
      normal n, 
    catch /.*/
      echom "GotoNonBlankColumn: pattern not found"
    endtry
  endif
  normal zz

  " return search state
  let @/=@s
  let v:hlsearch=@d
  let &hls=1
  " return cursor
  call cursor(line('.'), init_col)
  " return selection (in case in visual mode)
  if a:1 == "visual"
    normal msgv`s
  endif
  " return column horizontal view 
  if init_h_scroll-1 > 0
    execute 'normal '.init_h_scroll."zl"
  endif
endfunction
:command! -nargs=* -range GotoNonBlankColumn call s:GotoNonBlankColumn(<f-args>)
" to next/prev non blank column
nmap <a-k> :GotoNonBlankColumn normal p<cr>
nmap <a-j> :GotoNonBlankColumn normal<cr>
" we add escape so the script will remember the original column
vmap <a-k> <esc>:GotoNonBlankColumn visual p<cr>
vmap <a-j> <esc>:GotoNonBlankColumn visual<cr>

" goto to next/prev blank/non-blank column
function! s:GotoNonBlankColumnRight(...)
  " remember search state, and last search string, because we want to use it, and don't want user lose his/hers
  let &hls=0
  let @d=v:hlsearch
  let @s=@/
  let prev_col = col('.')
  " construct search string
  " let prefix = substitute(getline('.')[:col('.')-2],'.','.','g')
  " let @/='^'.prefix.'\S'
  let @/='^.\{'.col('.').'}'
  " go search
  if len(a:000) > 0 && a:1 == 'p'
    normal NN, 
  else
    normal n, 
  endif
  " return cursor
  call cursor(line('.'), prev_col)
  " return search state
  let @/=@s
  let v:hlsearch=@d
  let &hls=1
  " return selection (in case in visual mode)
  " normal msgv's
endfunction
:command! -nargs=* GotoNonBlankColumnRight call s:GotoNonBlankColumnRight(<f-args>)

" testing
" g:custom_gnbc_auto_pipe_mode
" aaa
"   aaa
"   aaa
"   aaa
" aaaa
