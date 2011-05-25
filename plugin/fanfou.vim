" Name Of File: fanfou.vim
" Description:  Playing Fanfou in Vim
" Last Change:  2011年 05月 25日 星期三 10:35:49 CST
" Maintainer:   Vayn <vayn@vayn.de>
" License:      Vim lincense. See ":help license"
" Usage:
"
" First of all, you must set your username and password of fanfou.com.
" For example:
"
"   let g:fanfou_login = "Username:Password"
"
" You should copy this line to your vimrc file, or comment out it in this
" script.
"
"
" This plugin defines three commands:
"
"   FanTimeline - Fetch latest timeline from Fanfou
"   FanUpdate - Update status in command line
"   FanUpline - Send the line which is cursor on
"
"
" By default,
" <leader>fft is mapped to FanTimeline,
" <leader>ffu is mapped to FanUpdate,
" <leader>ffs is mapped to FanUpline.
"
" If you want to use other key mappings, you could set mapping like this:
"
"   nmap ,fft <Plug>FanfouTimeline
"   nmap ,ffu <Plug>FanfouUpdate
"   nmap ,ffs <Plug>FanfouUpline
"
"
" Timeline window closes automatically: 
"
"   let g:fanfou_pvw = 1
"
" If you don't want to close timeline automatically, add this to your vimrc file
" and assign it to 0
"
" GetLatestVimScripts: 3596 0.2.0 Fanfou.vim
"

if exists("g:loaded_fanfou")
    finish
endif
let g:loaded_fanfou = 1

if !has('python')
    echoerr "Error: the fanfou.vim plugin requires Vim to be compiled with +python"
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

let s:source = 'fanfouvim'
let s:timeline_api = 'http://api.fanfou.com/statuses/friends_timeline.json'
let s:update_api = 'http://api.fanfou.com/statuses/update.xml'

let s:login = ""
let s:limit = 140

if !exists("g:fanfou_pvw")
    let g:fanfou_pvw = 1
endif

if !hasmapto('<Plug>Fanfou*')
    map <unique> <Leader>fft <Plug>FanfouTimeline
    map <unique> <Leader>ffu <Plug>FanfouUpdate
    map <unique> <Leader>ffs <Plug>FanfouUpline
endif
noremap <unique> <script> <Plug>FanfouTimeline <SID>Timeline
noremap <unique> <script> <Plug>FanfouUpdate   <SID>Update
noremap <unique> <script> <Plug>FanfouUpline   <SID>Upline

noremap <SID>Timeline   :call <SID>Timeline()<CR>
noremap <SID>Update     :call <SID>Update(input("type status: "))<CR>
noremap <SID>Upline     :call <SID>Update(getline("."))<CR>

fun s:Login()
    if exists('g:fanfou_login')
        let s:login = g:fanfou_login
    else
        let acc = input("type your account: ")
        let pass = inputsecret("type your password: ")
        let s:login = acc . ':' . pass
    endif
endf

fun s:Timeline()
    call s:Login()
    let tmp = tempname()
    try
        call system("curl -u " . s:login . " " . s:timeline_api . " > " . tmp)
        python << EOF
import simplejson
import vim

def ParseTimeline(filename):
    f = open(filename, 'r+')
    json = f.read()
    data = simplejson.loads(json)
    try:
        tweets = [item['user']['name']+': '+item['text'] for item in data]
        f.seek(0)
        f.write('\n'.join(tweets).encode('utf8'))
    except TypeError:
        f.seek(0)
        f.write('Invalid username or password.')
    f.truncate()
    f.close()

ParseTimeline(vim.eval("tmp"))
EOF
        exe 'pedit' . tmp
        exe 'wincmd P'
        exe 'set buftype=nofile'
        exe 'setlocal noswapfile'
        exe 'normal gg'
        call s:ClosePreviewWindow()
    finally
        call delete(tmp)
    endtry
endf

fun s:Update(str)
    call s:Login()
    let length = strlen(substitute(a:str, ".", "1", "g"))
    if length > s:limit
        echoerr "Your message is longer than 140, please shorten it."
    elseif length < 1
        echoerr "Your message is too short."
    else
        let ret = system("curl -u " . s:login . " -d status='" . a:str .
                    \ "' -d source=" . s:source . " " . s:update_api)
        if ret !~ "error"
            echo "Update successfully."
        else
            echoerr "Oops. Please check your settings and network."
        endif
    endif
endf

fun s:ClosePreviewWindow()
    if g:fanfou_pvw == 1
        exe 'au WinLeave <buffer> pc'
    endif
endf

if !exists(":FanTimeline")
    command FanTimeline  :call s:Timeline()
endif

if !exists(":FanUpdate")
    command -nargs=1 FanUpdate  :call s:Update(<q-args>)
endif

if !exists(":FanUpline")
    command FanUpline  :call s:Update(getline("."))
endif

let &cpo = s:save_cpo
