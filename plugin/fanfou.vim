" Name Of File: fanfou.vim
" Description:  Playing Fanfou in Vim
" Last Change:  2011年 05月 26日 星期四 16:41:09 CST
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
" GetLatestVimScripts: 3596 1 Fanfou.vim
"

if exists("g:loaded_fanfou")
    finish
endif
let g:loaded_fanfou = 1

if !has('python')
    echoerr "Error: the fanfou.vim plugin requires Vim to be compiled with +python"
    finish
endif

let s:version = '0.3.1'
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


fun s:Timeline()
    call s:Requester(s:timeline_api, 0)
    let tmp = tempname()
    try
        python << EOF
def ParseTimeline(filename):
    try:
        json = urllib2.urlopen(req).read()
        data = loads(json)
        tweets = [item['user']['name']+': '+item['text'] for item in data]
        open(filename, 'w').write('\n'.join(tweets).encode('utf8'))
    except:
        vim.command("echoerr 'Invalid username or password.'")

ParseTimeline(vim.eval("tmp"))
EOF
        exe 'pedit' . tmp
        exe 'wincmd P'
        exe 'set buftype=nofile'
        exe 'setlocal noswapfile'
        exe 'normal gg'
        call s:ClosePreviewWindow()
    fina
        call delete(tmp)
    endt
endf

fun s:Update(str)
    let length = strlen(substitute(a:str, '.', '1', 'g'))
    if length > s:limit
        echoerr 'Your message is longer than 140, please shorten it.'
    elseif length < 1
        echoerr 'Your message is too short.'
    else
        call s:Requester(s:update_api, a:str)
        try
            exe 'py urllib2.urlopen(req).read()'
            echo 'Update successfully.'
        catch
            echoerr 'Oops. Please check your account and network.'
        endt
    endif
endf


fun s:Requester(api, param)
    if exists('g:fanfou_login')
        let s:login = g:fanfou_login
    else
        let acc = input('type your account: ')
        let pass = inputsecret('type your password: ')
        let s:login = acc . ':' . pass
    endif
    python << EOF
import urllib
import urllib2
import vim

try:
    from simplejson import loads
except ImportError:
    vim.command("echoerr 'Fanfou.vim requires Python module simplejson.'")

api = vim.eval('a:api')
account = vim.eval('s:login').split(':', 1)
auth = urllib2.HTTPPasswordMgrWithDefaultRealm()
auth.add_password(None, api, account[0], account[1])

handler = urllib2.HTTPBasicAuthHandler(auth)
opener = urllib2.build_opener(handler)
urllib2.install_opener(opener)

if vim.eval('a:param') == 0:
    param = None
else:
    param = urllib.urlencode({'status': vim.eval('a:param'),
                            'source': vim.eval('s:source')})
req = urllib2.Request(api, param)
EOF
endf

fun s:ClosePreviewWindow()
    if g:fanfou_pvw == 1
        exe 'set title titlestring=Fanfou.vim\ ' . s:version
        exe 'au WinLeave <buffer> set title titlestring&'
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
