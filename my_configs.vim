set t_Co=256
set mouse-=a
set background=dark
set termguicolors
" colorscheme solarized
let g:ctrlp_max_files=0
let g:gitgutter_enabled = 1
let g:gitgutter_signs = 1
set updatetime=100
set number
set cursorline
autocmd BufWritePre * :%s/\s\+$//e

let g:go_fmt_command = "goimports"

call plug#begin('~/.vim_runtime/my_plugins')
Plug 'fatih/vim-go'
Plug 'SirVer/ultisnips'
Plug 'junegunn/fzf', { 'do': { -> fzf#install()  }  }
Plug 'junegunn/fzf.vim'
Plug 'https://github.com/ycm-core/YouCompleteMe'
call plug#end()

nnoremap <c-f> :Files<cr>
nnoremap <Leader>f :Ag<cr>
" Mapping selecting mappings
nmap <leader><tab> <plug>(fzf-maps-n)
xmap <leader><tab> <plug>(fzf-maps-x)
omap <leader><tab> <plug>(fzf-maps-o)

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-l> <plug>(fzf-complete-line)

let g:UltiSnipsExpandTrigger="<Leader><Tab>"
let g:python3_host_prog='/usr/bin/python3'
let g:python_host_prog='/usr/bin/python3'
