" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#paths#asset(name) abort " {{{1
  return vimtex#paths#join(s:root, 'assets/' . a:name)
endfunction

let s:root = resolve(expand('<sfile>:p:h:h:h'))

" }}}1

function! vimtex#paths#pushd(path) abort " {{{1
  if empty(a:path) || getcwd() ==# fnamemodify(a:path, ':p')
    let s:qpath += ['']
  else
    let s:qpath += [getcwd()]
    execute s:cd fnameescape(a:path)
  endif
endfunction

" }}}1
function! vimtex#paths#popd() abort " {{{1
  let l:path = remove(s:qpath, -1)
  if !empty(l:path)
    execute s:cd fnameescape(l:path)
  endif
endfunction

" }}}1

function! vimtex#paths#join(root, tail) abort " {{{1
  return vimtex#paths#s(a:root . '/' . a:tail)
endfunction

" }}}1

function! vimtex#paths#s(path) abort " {{{1
  " Handle shellescape issues and simplify path
  let l:path = exists('+shellslash') && !&shellslash
        \ ? tr(a:path, '/', '\')
        \ : a:path

  return simplify(l:path)
endfunction

" }}}1
function! vimtex#paths#is_abs(path) abort " {{{1
  return a:path =~# s:re_abs
endfunction

" }}}1

function! vimtex#paths#shorten_relative(path) abort " {{{1
  " Input: An absolute path
  " Output: Relative path with respect to the VimTeX root, path relative to
  "         VimTeX root (unless absolute path is shorter)

  let l:relative = vimtex#paths#relative(a:path, b:vimtex.root)
  return strlen(l:relative) < strlen(a:path)
        \ ? l:relative : a:path
endfunction

" }}}1
function! vimtex#paths#relative(path, current) abort " {{{1
  " Note: This algorithm is based on the one presented by @Offirmo at SO,
  "       http://stackoverflow.com/a/12498485/51634

  let l:target = simplify(substitute(a:path, '\\', '/', 'g'))
  let l:common = simplify(substitute(a:current, '\\', '/', 'g'))

  " This only works on absolute paths
  if !vimtex#paths#is_abs(l:target)
    return substitute(a:path, '^\.\/', '', '')
  endif

  if has('win32')
    let l:target = substitute(l:target, '^\a:', '', '')
    let l:common = substitute(l:common, '^\a:', '', '')
  endif

  if l:common[-1:] ==# '/'
    let l:common = l:common[:-2]
  endif

  let l:tries = 50
  let l:result = ''
  while stridx(l:target, l:common) != 0 && l:tries > 0
    let l:common = fnamemodify(l:common, ':h')
    let l:result = empty(l:result) ? '..' : '../' . l:result
    let l:tries -= 1
  endwhile

  if l:tries == 0 | return a:path | endif

  if l:common ==# '/'
    let l:result .= '/'
  endif

  let l:forward = strpart(l:target, strlen(l:common))
  if !empty(l:forward)
    let l:result = empty(l:result)
          \ ? l:forward[1:]
          \ : l:result . l:forward
  endif

  return l:result
endfunction

" }}}1


let s:cd = haslocaldir()
      \ ? 'lcd'
      \ : exists(':tcd') && haslocaldir(-1) ? 'tcd' : 'cd'
let s:qpath = get(s:, 'qpath', [])

let s:re_abs = has('win32') ? '^\a:[\\/]' : '^/'
