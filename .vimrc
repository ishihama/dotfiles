" setting
"文字コードをUTF-8に設定
set enc=utf-8
" バックアップファイルを作らない
set nobackup
" スワップファイルを作らない
set noswapfile
" 編集中のファイルが変更されたら自動で読み直す
set autoread
" バッファが編集中でもその他のファイルを開けるように
set hidden
" 入力中のコマンドをステータスに表示する
set showcmd


" 見た目系
" シンタックス
syntax on
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
" NERDTree
nnoremap <C-n> :NERDTreeToggle<CR>


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


" dein
"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('~/.cache/dein')
  call dein#begin('~/.cache/dein')

  " Let dein manage dein
  " Required:
  call dein#add('~/.cache/dein/repos/github.com/Shougo/dein.vim')

  " Add or remove your plugins here:
  call dein#add('Shougo/neosnippet.vim')
  call dein#add('Shougo/neosnippet-snippets')

  " You can specify revision/branch/tag.
  " call dein#add('Shougo/deol.nvim', { 'rev': 'a1b5108fd' })

  " 入力補完
  call dein#add('Shougo/neocomplcache.vim')
  " Ruby補完
  call dein#add('Shougo/neocomplcache-rsense.vim')
  " Ruby endwise 補完
  call dein#add('tpope/vim-endwise')
  " ファイル名補完 ctrl p
  call dein#add("ctrlpvim/ctrlp.vim")
  "　英単語補完
  call dein#add('ujihisa/neco-look')

  " rails
  call dein#add('tpope/vim-rails', {'on_ft' : 'ruby'})

  " 構文チェック
  call dein#add('scrooloose/syntastic')

  " ディレクトリツリー表示 ctrl n
  call dein#add('scrooloose/nerdtree')

  " nerdtree初期表示
  "autocmd VimEnter * execute 'NERDTree'
  let g:NERDTreeDirArrows = 1
  let g:NERDTreeDirArrowExpandable  = '▶'
  let g:NERDTreeDirArrowCollapsible = '▼'

  " ファイルアイコン
  "call dein#add('tiagofumo/vim-nerdtree-syntax-highlight')
  " ファイルアイコン
  "call dein#add('ryanoasis/vim-devicons')
  " スペース可視化
  call dein#add('bronson/vim-trailing-whitespace')

  " Git
  call dein#add('scrooloose/vim-fugitive')
  " Gitコマンドヘルパー
  "call dein#add('tpope/vim-fugitive')
  " Gitステータス行表示
  call dein#add('airblade/vim-gitgutter')

  " vimステータスライン表示
  call dein#add('itchyny/lightline.vim')

  " scala
  call dein#add('derekwyatt/vim-scala')

  " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

"End dein Scripts-------------------------

