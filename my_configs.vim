set encoding=utf-8
set t_Co=256
set mouse-=a
set background=dark
set termguicolors
" let g:solarized_termcolors=256
colorscheme onedark
let g:ctrlp_max_files=0
let g:gitgutter_enabled = 1
let g:gitgutter_signs = 1
set updatetime=100
set number
" set cursorline
autocmd BufWritePre * :%s/\s\+$//e

call plug#begin('~/.vim_runtime/my_plugins')
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'joshdick/onedark.vim'
Plug 'SirVer/ultisnips'
Plug 'junegunn/fzf', { 'do': { -> fzf#install()  }  }
Plug 'junegunn/fzf.vim'
Plug 'ycm-core/YouCompleteMe'
Plug 'lifepillar/vim-solarized8'
Plug 'easymotion/vim-easymotion'
Plug 'airblade/vim-gitgutter'
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'vim-airline/vim-airline-themes'
Plug 'honza/vim-snippets'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
call plug#end()
colorscheme onedark

let mapleader = ","

let g:UltiSnipsExpandTrigger="<F3>"
let g:UltiSnipsJumpForwardTrigger="<M-f>"
let g:UltiSnipsJumpBackwardTrigger="<M-b>"
let g:UltiSnipEditSplit="vertical"

let g:ycm_key_list_stop_completion=['<F4>']

let g:gitgutter_enabled = 1
let g:gitgutter_signs = 1

nnoremap <Leader>8 :Ag <c-r><c-w><cr>
nnoremap <Leader>f :Ag
nnoremap <c-f> :Files<cr>
nnoremap <c-b> :Buffers<cr>
" Mapping selecting mappings
nmap <leader><tab> <plug>(fzf-maps-n)
xmap <leader><tab> <plug>(fzf-maps-x)
omap <leader><tab> <plug>(fzf-maps-o)

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-l> <plug>(fzf-complete-line)

set ignorecase
set smartcase
set tabstop     =4
set softtabstop =4
set shiftwidth  =4
set expandtab
let g:airline#extentions#tabline#enabled = 1

fun! StripTailingWhitespace()
    %s/\s\+$//e
endfun
autocmd BufWritePre * call StripTailingWhitespace()

try
    set undodir=~/.vim_runtime/temp_dirs/undodir
    set undofile
catch
endtry

nmap <silent> <c-k> :wincmd k<CR>
nmap <silent> <c-j> :wincmd j<CR>
nmap <silent> <c-h> :wincmd h<CR>
nmap <silent> <c-l> :wincmd l<CR>

let g:NERDTreeWinPos = "left"
nnoremap <Leader>nf :NERDTreeFind<CR>

let g:ycm_key_list_select_completion=['<Tab>', '<Down>']
let g:ycm_key_list_previous_completion=['<S-Tab>', '<Up>']
map <M-n> :LspHover<CR>

let g:python3_host_prog='~/.pyenv/versions/3.10.14/bin/python'
let g:python_host_prog='~/.pyenv/versions/3.10.14/bin/python'
let g:go_fmt_command = "goimports"
let g:lsp_preview_float = 0
let g:lsp_documentation_float = 0

inoremap ( ()<Esc>i
inoremap { {}<Esc>i
inoremap {<CR> {<CR>}<Esc>O
inoremap [ []<Esc>i
inoremap < <><Esc>i
inoremap ' ''<Esc>i
inoremap " ""<Esc>i
vnoremap $1 <esc>`>a)<esc>`<i(<esc>
vnoremap $2 <esc>`>a]<esc>`<i[<esc>
vnoremap $3 <esc>`>a}<esc>`<i{<esc>
vnoremap $$ <esc>`>a"<esc>`<i"<esc>
vnoremap $q <esc>`>a'<esc>`<i'<esc>
vnoremap $e <esc>`>a`<esc>`<i`<esc>
