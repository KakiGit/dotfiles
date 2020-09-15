set t_Co=256
set mouse-=a
set background=dark
set termguicolors
colorscheme solarized
let g:ctrlp_max_files=0
let g:gitgutter_enabled = 1
let g:gitgutter_signs = 1
set updatetime=100
set number
set cursorline
autocmd BufWritePre * :%s/\s\+$//e
