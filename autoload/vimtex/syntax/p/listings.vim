" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#listings#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'listings') | return | endif
  let b:vimtex_syntax.listings = 1

  " First some general support
  syntax match texInputFile
        \ "\\lstinputlisting\s*\(\[.*\]\)\={.\{-}}"
        \ contains=texStatement,texInputCurlies,texInputFileOpt
  syntax match texZone "\\lstinline\s*\(\[.*\]\)\={.\{-}}"

  " Set all listings environments to listings
  syntax cluster texFoldGroup add=texZoneListings
  syntax region texZoneListings
        \ start="\\begin{lstlisting}\(\_s*\[\_[^\]]\{-}\]\)\?"rs=s
        \ end="\\end{lstlisting}\|%stopzone\>"re=e
        \ keepend
        \ contains=texBeginEnd

  " Next add nested syntax support for desired languages
  for l:entry in get(g:, 'vimtex_syntax_listings', [])
    let l:lang = l:entry.lang
    let l:syntax = get(l:entry, 'syntax', l:lang)

    let l:cap_name = toupper(l:lang[0]) . l:lang[1:]
    let l:group_main = 'texZoneListings' . l:cap_name
    let l:group_lstset = l:group_main . 'Lstset'
    let l:group_contained = l:group_main . 'Contained'
    execute 'syntax cluster texFoldGroup add=' . l:group_main
    execute 'syntax cluster texFoldGroup add=' . l:group_lstset

    unlet b:current_syntax
    execute 'syntax include @' . toupper(l:lang) 'syntax/' . l:syntax . '.vim'
    let b:current_syntax = 'tex'

    if has_key(l:entry, 'ignore')
      execute 'syntax cluster' toupper(l:lang)
            \ 'remove=' . join(l:entry.ignore, ',')
    endif

    execute 'syntax region' l:group_main
          \ 'start="\c\\begin{lstlisting}\s*'
          \ . '\[\_[^\]]\{-}language=' . l:lang . '\%(\s*,\_[^\]]\{-}\)\?\]"rs=s'
          \ 'end="\\end{lstlisting}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texBeginEnd,@' . toupper(l:lang)

    execute 'syntax match' l:group_lstset
          \ '"\c\\lstset{.*language=' . l:lang . '\%(\s*,\|}\)"'
          \ 'transparent'
          \ 'contains=texStatement,texMatcher'
          \ 'skipwhite skipempty'
          \ 'nextgroup=' . l:group_contained

    execute 'syntax region' l:group_contained
          \ 'start="\\begin{lstlisting}"rs=s'
          \ 'end="\\end{lstlisting}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'containedin=' . l:group_lstset
          \ 'contains=texStatement,texBeginEnd,@' . toupper(l:lang)
  endfor

  highlight link texZoneListings texZone
endfunction

" }}}1