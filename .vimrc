" encoding
"文字コードをUTF-8に設定
set encoding=utf-8
scriptencoding utf-8

" 保存時の文字コード
set fileencoding=utf-8
" 読込時の文字コード
set fileencodings=ucs-boms,utf-8,cp932,euc-jp
" 改行コードの文字コード
set fileformats=unix,dos,mac

" file
" バックアップファイルを作らない
set nobackup
" スワップファイルを作らない
set noswapfile
" undoファイルを有効化（永続的なundo履歴）
set undofile
set undodir=~/.vim/undo
if !isdirectory(expand('~/.vim/undo'))
  call mkdir(expand('~/.vim/undo'), 'p')
endif
" 編集中のファイルが変更されたら自動で読み直す
set autoread
" バッファが編集中でもその他のファイルを開けるように
set hidden

" 見た目系
" シンタックス
syntax on
" True Color対応
set termguicolors
" 行番号を表示
set number
" 現在の行を強調表示
set cursorline
" 現在の行を強調表示（縦）
"set cursorcolumn
" 行末の1文字先までカーソルを移動できるように
set virtualedit=onemore
" インデントはスマートインデント
set smartindent
" ビープ音を可視化
set visualbell
" 括弧入力時の対応する括弧を表示
set showmatch
" ステータスラインを常に表示
set laststatus=2
" コマンドラインの補完
set wildmode=list:longest
" 折り返し時に表示行単位での移動できるようにする
nnoremap j gj
nnoremap k gk
" 入力中のコマンドをステータスに表示する
set showcmd
" □や○文字が崩れる問題を解
set ambiwidth=double

" Tab系
" 不可視文字を可視化(タブが「▸-」と表示される)
" set list listchars=tab:\▸\-
" Tab文字を半角スペースにする
set expandtab
" 行頭以外のTab文字の表示幅（スペースいくつ分）
set tabstop=2
" 行頭でのTab文字の表示幅
set shiftwidth=2

" 検索系
" 検索文字列が小文字の場合は大文字小文字を区別なく検索する
set ignorecase
" 検索文字列に大文字が含まれている場合は区別して検索する
set smartcase
" 検索文字列入力時に順次対象文字列にヒットさせる
set incsearch
" 検索時に最後まで行ったら最初に戻る
set wrapscan
" 検索語をハイライト表示
set hlsearch
" ESC連打でハイライト解除
nmap <Esc><Esc> :nohlsearch<CR><Esc>

" plugin settings
"
" NERDTree
nnoremap <C-n> :NERDTreeToggle<CR>

" nerdtree初期表示
"autocmd VimEnter * execute 'NERDTree'
let g:NERDTreeDirArrows = 1
let g:NERDTreeDirArrowExpandable  = '▶'
let g:NERDTreeDirArrowCollapsible = '▼'

" TagBar
nnoremap <F8> :TagbarToggle<CR>

" cheatsheet
let g:cheatsheet#cheat_file = '~/.cheatsheet.md'
nnoremap <F1> :Cheat<CR>

" lsp setting  refer: https://mattn.kaoriya.net/software/vim/20191231213507.htm
source ~/.vim/config/lsp.vim

" dein setting  refer: https://github.com/Shougo/dein.vim
source ~/.vim/config/dein.vim

