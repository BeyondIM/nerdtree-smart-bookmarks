let s:save_cpo = &cpo
set cpo&vim

" Prepare {{{1

let s:isWin = has('win32') || has('win64')
let s:isMac = has('unix') && substitute(system('uname'), '\n', '', '') =~# 'Darwin\|Mac' 
let s:isLinux = has('unix') && substitute(system('uname'), '\n', '', '') ==# 'Linux' 

" Check file whether is readable {{{2
function! s:CheckFileReadable(file)
    if !filereadable(a:file)
        silent! execute 'keepalt botright 1new'
        silent! execute 'edit ' . a:file
        silent! execute 'write!'
        silent! execute 'bwipeout!'
        silent! execute 'close!'
        if !filereadable(a:file)
            call s:EchoMsg(a:file." can't read!", 'warn')
            return
        endif
    endif
endfunction
" }}}2

" Check file whether is writable {{{2
function! s:CheckFileWritable(file)
    if !filewritable(a:file)
        call s:EchoMsg(a:file." can't write!", 'warn')
        return
    endif
endfunction
" }}}2

" echo message {{{2
function! s:EchoMsg(message,type)
    if a:type == 'warn'
        echohl WarningMsg | echo a:message | echohl None
    elseif a:type == 'error'
        echohl ErrorMsg | echo a:message | echohl None
    endif
endfunction
" }}}2

" }}}1

" bookmark object {{{1

let s:bookmark = {}

function! s:bookmark.new(name, path)
    let newBookmark = copy(self)
    let newBookmark.name = self.genName(a:name)
    let newBookmark.path = self.genPath(a:path)
    return newBookmark
endfunction

function! s:bookmark.genPath(path)
    let path = substitute(expand(a:path, 1), '\\ ', ' ', 'g')
    let path = substitute(path, '[\\/]$', '', '')
    return path
endfunction

function! s:bookmark.genName(name)
    let name = substitute(a:name, ' ', '_', 'g')
    return name
endfunction

" }}}1

" nsb function {{{1

let s:init = 0
let g:nsbList = []

" nsb#readParams {{{2
function! nsb#readParams()
    call s:CheckFileReadable(g:NERDTreeBookmarksFile)
    let content = readfile(g:NERDTreeBookmarksFile)
    let content = filter(copy(content), 'v:val != ""')
    if !empty(content)
        for line in content
            let name = substitute(line, '^\(.\{-}\) .*$', '\1', '')
            let path = substitute(line, '^.\{-} \(.*\)$', '\1', '')
            call add(g:nsbList, s:bookmark.new(name, path))
        endfor
    endif
endfunction
" }}}2

" nsb#writeParams {{{2
function! nsb#writeParams()
    if !s:init
        return
    endif
    call s:CheckFileReadable(g:NERDTreeBookmarksFile)
    call s:CheckFileWritable(g:NERDTreeBookmarksFile)
    let content = []
    for i in g:nsbList
        let str = i.name . ' ' . i.path
        call add(content, str)
    endfor
    call writefile(content, g:NERDTreeBookmarksFile)
endfunction
" }}}2

" nsb#addBookmark {{{2
function! nsb#addBookmark()
    let path = input('Directory to bookmark: ', '', 'dir')
    let name = input('Bookmark as: ')
    if empty(path) || empty(name)
        return
    endif
    let b = s:bookmark.new(name, path)
    for i in g:nsbList
        if i.path ==# b.path
            let i.name = b.name
            return
        endif
    endfor
    call insert(g:nsbList, b, 0)
endfunction
" }}}2

" nsb#editBookmark {{{2
function! nsb#editBookmark(idx)
    let b = g:nsbList[a:idx]
    let path = input('Change directory to bookmark: ', escape(b.path, ' ') . (s:isWin ? '\' : '/'), 'dir')
    let name = input('Change bookmark as: ', b.name)
    let b.path = empty(path) ? b.path : b.genPath(path)
    let b.name = empty(name) ? b.name : b.genName(name)
endfunction
" }}}2

" nsb#delBookmark {{{2
function! nsb#delBookmark(idx)
    call remove(g:nsbList, a:idx)
endfunction
" }}}2

" nsb#delBookmarks {{{2
function! nsb#delBookmarks()
    if !empty(g:nsbList)
        call remove(g:nsbList, 0, -1)
    endif
endfunction
" }}}2

" nsb#openBookmark {{{2
function! nsb#openBookmark(idx)
    silent! execute 'NERDTree ' . g:nsbList[a:idx].path
endfunction
" }}}2

" nsb#handle {{{2
function! nsb#handle(key)
    if !empty(matchstr(a:key, '[1-9]'))
        hide
        call nsb#openBookmark(a:key-1)
        return
    endif

    let pos = getpos(".")
    let idx = pos[1]>2 ? (pos[1]-3) : -1
    if a:key ==# 'q'
        hide
    endif
    if a:key ==# 'o'
        if idx == -1
            return
        endif
        hide
        call nsb#openBookmark(idx)
    endif
    if a:key ==# 'a'
        call nsb#addBookmark()
        hide
        call nsb#init()
        call setpos(".", [0, 3, 1, 0])
    endif
    if a:key ==# 'e'
        if idx == -1
            return
        endif
        call nsb#editBookmark(idx)
        hide
        call nsb#init()
        call setpos(".", [0, pos[1], 1, 0])
    endif
    if a:key ==# 'd'
        if idx == -1
            return
        endif
        call nsb#delBookmark(idx)
        hide
        call nsb#init()
    endif
    if a:key ==# 'D'
        call nsb#delBookmarks()
        hide
        call nsb#init()
    endif
endfunction
" }}}2

" nsb#render {{{2
function! nsb#render()
    let s:nameMaxLen = 0
    for i in g:nsbList
        let s:nameMaxLen = strlen(i.name) > s:nameMaxLen ? strlen(i.name) : s:nameMaxLen
    endfor
    let output = []
    for i in g:nsbList
        let idx = index(g:nsbList, i)
        let pre = idx>8 ? repeat(' ', 3) : (idx+1).'. '
        let sep = repeat(' ', s:nameMaxLen-strlen(i.name)).' => '
        call add(output, pre . i.name . sep . i.path)
    endfor
    return output
endfunction
" }}}2

" nsb#init {{{2
function! nsb#init()
    if !s:init
        call nsb#readParams()
        let s:init = 1
    endif
    " always switch to the [SmartNERDTreeBookmark] buffer if exists
    if !exists('s:bmBufferId')
        let s:bmBufferId = -1
    endif
    if !exists('s:bmBufferName')
        let s:bmBufferName = '[SmartNERDTreeBookmark]'
    endif
    if bufwinnr(s:bmBufferId) == -1
        silent! execute 'keepalt botright ' . (len(g:nsbList)>0 ? len(g:nsbList)+2 : 3) . 'split'
        silent! execute 'edit ' . s:bmBufferName
        let s:bmBufferId = bufnr('%') + 0
    else
        silent! execute bufwinnr(s:bmBufferId) . 'wincmd w'
    endif
    " set buffer environment
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nowrap
    setlocal nonumber
    setlocal norelativenumber
    setlocal nobuflisted
    setlocal statusline=%f
    setlocal noreadonly
    setlocal modifiable
    " key mapping
    mapclear <buffer>
    nnoremap <buffer> <silent> <CR> :<C-U>call nsb#handle('o')<CR>
    nnoremap <buffer> <silent> 1 :<C-U>call nsb#handle(1)<CR>
    nnoremap <buffer> <silent> 2 :<C-U>call nsb#handle(2)<CR>
    nnoremap <buffer> <silent> 3 :<C-U>call nsb#handle(3)<CR>
    nnoremap <buffer> <silent> 4 :<C-U>call nsb#handle(4)<CR>
    nnoremap <buffer> <silent> 5 :<C-U>call nsb#handle(5)<CR>
    nnoremap <buffer> <silent> 6 :<C-U>call nsb#handle(6)<CR>
    nnoremap <buffer> <silent> 7 :<C-U>call nsb#handle(7)<CR>
    nnoremap <buffer> <silent> 8 :<C-U>call nsb#handle(8)<CR>
    nnoremap <buffer> <silent> 9 :<C-U>call nsb#handle(9)<CR>
    nnoremap <buffer> <silent> q :<C-U>call nsb#handle('q')<CR>
    nnoremap <buffer> <silent> <ESC> :<C-U>call nsb#handle('q')<CR>
    nnoremap <buffer> <silent> a :<C-U>call nsb#handle('a')<CR>
    nnoremap <buffer> <silent> d :<C-U>call nsb#handle('d')<CR>
    nnoremap <buffer> <silent> D :<C-U>call nsb#handle('D')<CR>
    nnoremap <buffer> <silent> e :<C-U>call nsb#handle('e')<CR>
    " show bookmarks
    let desc = repeat(' ', 3) .
                \'1-9 or CR = open, a = add, d = delete, D = delete all, e = edit, q or ESC = quit' .
                \repeat(' ', 3)
    let desc = desc . "\n" . repeat('-', strlen(desc))
    silent! execute '%delete _'
    silent! put! = desc
    silent! put = nsb#render()
    if empty(getline('$'))
        silent! execute '$delete _'
    endif
    " let buffer can't be modified
    setlocal readonly
    setlocal nomodifiable
endfunction
" }}}2

" }}}1

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set shiftwidth=4 tabstop=4 softtabstop=4 expandtab foldmethod=marker:
