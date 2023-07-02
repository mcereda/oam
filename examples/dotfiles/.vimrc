""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" ~/.vimrc
""
"" Sources:
"" - http://vimdoc.sourceforge.net/htmldoc/filetype.html
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Attempt to determine the type of a file based on its name and possibly its
" contents.
" Allow intelligent auto-indenting for each filetype, and for plugins that are
" filetype specific.
filetype indent plugin on

" Enable syntax highlighting.
syntax on

" Display line numbers on the left-hand side.
set number

" Highlight the line underneath the cursor.
set cursorline

" Highlight the column underneath the cursor.
" set cursorcolumn

" Highlight matching brackets.
set showmatch

" Show typed partial commands in the last line of the screen.
set showcmd

" Show the mode you are on the last line.
" set showmode

" Display the cursor position on the last line of the screen or in the status
" line of a window.
set ruler

" Use visual bell instead of beeping when doing something wrong.
set visualbell

" Raise a dialogue asking if you wish to save changed files instead of failing a
" command because of unsaved changes.
set confirm

" Do not redraw the screen during important tasks.
" Leads to smoother and faster macros.
set lazyredraw

""""""""""""""""""""""""""""""""""""""""
" Search.
""""""""""""""""""""""""""""""""""""""""

" Ignore capital letters during search.
set ignorecase

" Override the ignorecase option if searching for capital letters.
" This allows to search specifically for capital letters.
set smartcase

" Highlight during a search.
set hlsearch

" Highlight matching characters as you type while searching though a file
" incrementally.
set incsearch

" Show matching words during a search.
set showmatch

""""""""""""""""""""""""""""""""""""""""
" Indentation.
""""""""""""""""""""""""""""""""""""""""

" Copy indentation from the current line when starting a new line
set autoindent

" Adjust indentation on special events (e.g. after a bracket start)
set smartindent

" Insert spaces instead of a tab
set expandtab

" Draw a tab as 4 spaces
set tabstop=4

" Number of spaces to use for each (auto)indent step
set shiftwidth=4

" Number of spaces the cursor moves right when a Tab is inserted and moves left
" when Backspace is used to erase a tab.
" A negative value sets it to fall back to the value of 'shiftwidth'
set softtabstop=-1

" Overrides for shell files
" Use tabs for indentation instead of spaces
autocmd Filetype sh setlocal softtabstop=0 noexpandtab

""""""""""""""""""""""""""""""""""""""""
" Line wrap
""""""""""""""""""""""""""""""""""""""""

" Paint the background of the 81st character to draw a vertical indicator.
set colorcolumn=81

" Make it black in Graphical Vim.
" See :help gui-colors for a list of suggested color names.
" See :help guibg for how to specify specific rgb/hex colors.
highlight ColorColumn guibg=Black

" Make it dark grey in terminal vim.
" See :help cterm-colors for a list of colors that can be used in the terminal.
highlight ColorColumn ctermbg=DarkGrey
