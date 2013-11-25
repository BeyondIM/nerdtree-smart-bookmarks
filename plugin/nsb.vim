" NERDTree-Smart-Bookmarks: A vim plugin to manage NERDTree bookmarks smartly.
" Author: BeyondIM <lypdarling at gmail dot com>
" HomePage: https://github.com/BeyondIM/nerdtree-smart-bookmarks
" License: MIT license
" Version: 0.1

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:mapleader')
    let g:mapleader=","
endif
nnoremap <silent> <Leader>nb :<C-U>call nsb#init()<CR>
autocmd VimLeavePre * call nsb#writeParams()

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set shiftwidth=4 tabstop=4 softtabstop=4 expandtab foldmethod=marker:
