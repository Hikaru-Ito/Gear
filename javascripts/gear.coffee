#
# gear.js - 単純装置で階層的コンテンツを閲覧する
#
# node-webkitで動くようにしたもの
# 
# http://GitHub.com/masui/Gear
#

useAnimation =       true        unless useAnimation?        # アニメーションを使うかどうか
showContents =       true        unless showContents?        # メニューだけだでなく内容も表示するか
autoexpand =         true        unless autoexpand?          # 自動展開(デフォルト動作)
pauseAtLevelChange = true        unless pauseAtLevelChange?
dontShowSingleNode = true        unless dontShowSingleNode?  # 辞書に使うときとか
singleWindow =       false       unless singleWindow?        # メニューとコンテンツを同じ画面にするかどうか
json =               'data.json' unless json?

node_app = typeof(require) != 'undefined' # node-webkitによるアプリかどうか
singleWindow = true if node_app

if singleWindow
  menuFontSize = 18
  lineHeight = 30
else
  menuFontSize = 11
  lineHeight = 20

nodeList = {}     # 表示可能ノードのリスト. nodeList[0]を中心に表示する
oldNodeList = {}
spans = {}        # 表示されるspan要素のリスト
oldSpans = {}

StepTime = 1000         # 段階的展開のタイムアウト時間   ?????
ExpandTime = 1500       # 無操作時展開のタイムアウト時間
expandTimeout = null

AnimationTime = 300     # ズーミングのアニメーション時間

HideTime = 1600         # 無操作時にメニューを消すまでの時間
HideAnimationTime = 700 # メニューが消えるアニメーションの時間
hideTimeout = null

typeCount = 0           # 連打したかどうか: 連打されてたら表示を行なう
typeCountTimeout = null

loadData = ->
  $.getJSON json, (data) ->
    initData data, null, 0
    calc data[0]
    expandTimeout = setTimeout expand, ExpandTime

initData = (nodes,parent,level) -> # 木構造をセットアップ
  #for i, node of nodes
  for i in [0...nodes.length]
    node = nodes[i]
    node.level = level
    node.elder = (if i > 0 then nodes[i-1] else null)
    node.younger = (if i < nodes.length-1 then nodes[i+1] else null)
    node.parent = parent
    initData(node.children,node,level+1) if node.children

$ -> # document.ready()
  if node_app
    # v0.10からMacではこれが必要らしい
    nw = require 'nw.gui'
    win = nw.Window.get()
    nativeMenuBar = new nw.Menu
      type: "menubar"
    if nativeMenuBar.createMacBuiltin
      nativeMenuBar.createMacBuiltin "Gear",
        hideEdit: true
        hideWindow: true
      win.menu = nativeMenuBar
     window.addEventListener "resize", ->
        win.enterFullscreen()
      ,false
  loadData()

  if showContents
    if singleWindow
    else # コンテンツ表示ウィンドウを開く
      height = screen.availHeight
      menuwidth = screen.availWidth / 5
      menuwidth = 300 if menuwidth > 300
      width = screen.availWidth - menuwidth
      param = "top=0,left=#{menuwidth},height=#{height},width=#{width},scrollbars=yes"
      $.contentswin = window.open "","Contents",param

  if singleWindow
    $('#menu').css('left','200pt')
  else
    $('#menu').css('left','10pt')

refresh = -> # 不要DOMを始末する. 富豪的すぎるかも?
  span.show() for i, span of spans
  span.remove() for i, span of oldSpans

browserHeight = -> # jQuery式の標準関数がありそうだが?
  if window.innerHeight
    return window.innerHeight
  if document.body
    return document.body.clientHeight
  return 0

resizefunc = ->
  height = screen.height
  width = screen.width
  $('body').css('width',width)
  $('body').css('height',height)
  $('#iframe').css('width',width)
  $('#iframe').css('height',height)
  $('#image').css('width',width)
  $('#image').css('height',height)
  $('#menu').css('height',height)
  $('#panel').css('width',width)
  $('#panel').css('height',height)

expand = -> # 注目してるエントリの子供を段階的に展開する
  if singleWindow
    clearTimeout hideTimeout
    hideTimeout = setTimeout hideLines, HideTime

  expandTimeout = null
  shrinking = false
  if nodeList[0].children
    calc nodeList[0].children[0]
    expandTimeout = setTimeout expand, StepTime

intValue = (s) ->
  Number s.replace(/px/,'')

hideLines = ->
  $('span').animate
    opacity:0.0
  , HideAnimationTime

dispLine = (node,ind,top,color,bold,parent,showloading) ->
  if singleWindow
    return if typeCount < 2 && !nodeList[0].children

  span = $('<span>')
  span.attr 'class', 'line'
  span.css 'width', parent.css('width')
  span.css 'color', color
  span.css 'top', String(top)
  span.css 'font-weight','bold' if bold
  span.css 'font-size',menuFontSize+'pt'

  span.text Array(node.level+1).join("　")+'・' + node.title # strをx回繰り返し

  if showloading # ローディングGIFアニメ表示
    #  http://preloaders.net/ で作成したロード中アイコンを利用
    span.append $(' <span>&nbsp;</span>')
    span.append $('<img src="images/loading.gif" style="height:12pt;">')

  parent.append span

  span.hide() if useAnimation
  spans[ind] = span
  node.span = span

hashIndex = (hash,entry) -> # ハッシュの値を検索. 標準関数ないのか?
  for key, val of hash
    return key if val == entry
  return null;

calc = (centerNode) -> # centerNodeを中心にnodeListを再計算して表示
  newNodeList = {} # 毎回富豪的にリストを生成
  newNodeList[0] = centerNode
  node = centerNode
  i = 0
  while node = nextNode node
    newNodeList[++i] = node
  node = centerNode;
  i = 0
  while node = prevNode node
    newNodeList[--i] = node
  display newNodeList

nextNode = (node) ->
  nextnode = node.younger
  while !nextnode && node.parent
    node = node.parent
    nextnode = node.younger
  nextnode

prevNode = (node) ->
  prevnode = node.elder
  while !prevnode && node.parent
    prevnode = node.parent
  prevnode

nasty = (url) -> # 意地悪サイト
  url.match(/twitter\.com/i) ||
  url.match(/www\.ted\.com/i)

display = (newNodeList) -> # calc()で計算したリストを表示
  oldNodeList = nodeList
  nodeList = newNodeList
  oldSpans = spans
  spans = {}

  center = browserHeight() / 2

  # コンテンツに応じてiframeなどを表示
  # 
  url = nodeList[0].url
  if url && showContents
    if singleWindow
      if showContents && !nasty(url)
        if url.match /(gif|jpg|jpeg|png)$/i
          $('#iframe').css 'display','none'
          $('#image').css 'display','block'
          $('#image').attr 'src',url
        else
          $('#iframe').css 'display','block'
          $('#image').css 'display','none'
          $('#iframe').attr 'src',url
    else
    	$.contentswin.location.href = url

  # 新しいノードの表示位置計算
  node = nodeList[0]
  menu = $('#menu')
  dispLine node, 0, center, '#0000ff', true, menu, node.children
  i = 1
  while node = nodeList[i]
    top = center + i * lineHeight
    break if top > browserHeight() - 40
    dispLine node, i, top, '#000000', false, menu, false
    i += 1
  i = -1
  while node = nodeList[i]
    top = center + i * lineHeight
    break if top < 0
    dispLine node, i, top, '#000000', false, menu, false
    i -= 1

  # アニメーション表示
  if useAnimation
    for i, oldnode of oldNodeList # 古いエントリの扱いを調査
      if j = hashIndex nodeList, oldnode # 新しいリストに存在するか調査
        if spans[j] # 見える場所に移動する場合
          if oldSpans[i]
            oldSpans[i].animate # 移動アニメーション
              top: nodeList[j].span.css 'top'
            ,
              duration: AnimationTime
              complete: ->
                typeCount = 2
                refresh()
        else # 見えなくなるエントリは即座に消す
          if oldnode.span
            oldnode.span.hide()
      else # 古いエントリが消える場合
        if shrinking?
          if j = hashIndex nodeList, oldnode.parent # 親の位置にシュリンクしながら消える
            if oldSpans[i]
              oldSpans[i].animate
                top: nodeList[j].span.css 'top'
                color: '#ffffff'
                opacity: 0.1
              ,
                duration: AnimationTime
                complete: ->
                  this.remove()
                  typeCount = 2
                  refresh()
        else # 即座に消す
          if oldnode.span != undefined
            oldnode.span.hide()
  
    for i, newnode of nodeList # 新たに出現するエントリ
      if null == hashIndex oldNodeList, newnode
        parent = newnode.parent
        if parent && !shrinking? # 親の位置から出現する
          if j = hashIndex nodeList, parent
            if newnode.span
              dest = newnode.span.css('top')
              newnode.span.show()
              newnode.span.css('opacity',0)
              newnode.span.css('top',intValue(parent.span.css('top'))+20)
              newnode.span.animate
                top: dest
                color: '#000000'
                opacity: 1.0
              ,
                duration: AnimationTime
                complete: ->
                  typeCount = 2
                  refresh()

move = (delta, shrinkMode) -> # 視点移動
  if typeCount <= 2
    newcount = typeCount + 1
    newcount = 2 if newcount > 2
    clearTimeout typeCountTimeout
    typeCount = newcount
    typeCountTimeout = setTimeout ->
      typeCount = 0
    , 1000
  refresh()

  if singleWindow
    clearTimeout hideTimeout
    hideTimeout = setTimeout hideLines, HideTime

  clearTimeout expandTimeout
  if !$.mouseisdown
    expandTimeout = setTimeout expand, ExpandTime

  shrinking = true;

  if nodeList[delta]
    if shrinkMode == 0       # フォーカスがはずれたらシュリンクする
      calc nodeList[delta]
    else                     # 可逆的に
      newNodeList = {}
      i = 0
      while nodeList[i+delta]
        newNodeList[i] = nodeList[i+delta]
        i += 1
      i = -1
      while nodeList[i+delta]
        newNodeList[i] = nodeList[i+delta]
        i -= 1
      display newNodeList
  false

#$(window).blur(function(){ // ????
#    setTimeout(window.focus,100);
#});

$(window).mousewheel (event, delta, deltaX, deltaY) ->
  d = (if delta < 0 then 1 else -1)
  move d, 1

downfunc = (e) ->
  e.preventDefault()
  if e.type == 'mousedown'
    $.mousedowny = e.pageY
  if e.type == 'touchstart'
    $.mousedowny = event.changedTouches[0].pageY
  $.mouseisdown = true;

upfunc = (e) ->
  e.preventDefault()
  $.mouseisdown = false

  clearTimeout expandTimeout
  expandTimeout = setTimeout expand, ExpandTime

  $.step = 0

movefunc = (e) ->
  e.preventDefault()
  delta = 0
  if $.mouseisdown
    if e.type == 'mousemove'
      delta = e.pageY - $.mousedowny
    if e.type == 'touchmove'
      delta = event.changedTouches[0].pageY - $.mousedowny
    if delta > 0
      newstep = Math.floor(delta / 20.0)
      if newstep > $.step
        move(-1,1) for i in [0 ... newstep-$.step]
      else
        move(1,1) for i in [0 ... $.step-newstep]
    else
      newstep = Math.floor((0-delta) / 20.0)
      if newstep > $.step
        move(1,1) for i in [0 ... newstep-$.step]
      else
        move(-1,1) for i in [0 ... $.step-newstep]
    step = newstep

keydownfunc = (e) ->
  switch e.keyCode
    when 40 then move(1,0)  # 下
    when 39 then move(1,1)  # 右
    when 38 then move(-1,0) # 上
    when 37 then move(-1,1) # 左

$(window).on
  'mousedown':  downfunc
  'touchstart': downfunc
  'mouseup':    upfunc
  'touchend':   upfunc
  'mousemove':  movefunc
  'touchmove':  movefunc
  'keydown':    keydownfunc
  'resize':     resizefunc
