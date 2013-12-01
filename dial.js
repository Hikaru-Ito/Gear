//
// 回転ダイヤルであらゆるコンテンツを閲覧する
// 2013/12/1 増井
// 
// Issues:
//  * リストのアニメーション (必要か?)
//  * キーワードからの写真検索
//  * 富豪的実装のスリム化
//  * Wikipedia, 辞書などコンテンツ増強
//

var list;                 // 表示エントリのリスト. list[0]が表示中心

var timeout;
var StepTimeout = 600;    // 段階的展開のタイムアウト
var ExpandTimeout = 1500; // 無操作時に展開のタイムアウト

var win = window.open();  // YouTube, クックパッド等がiframeで表示できないので別ウィンドウを開く

$(function() {
    $.getJSON("data.json",function(data) {
	initdata(data,null,0);
	calc(data[0]);
	timeout = setTimeout(expand,ExpandTimeout);
    });
});

var browserHeight = function(){ // jQuery式の書き方がありそうだが?
    if(window.innerHeight){ return window.innerHeight; }  
    else if(document.body){ return document.body.clientHeight; }  
    return 0;  
};

// 表示中心を段階的に展開する
var expand = function(){
    timeout = null;
    if(list[0].children){
	calc(list[0].children[0]);
	timeout = setTimeout(expand,StepTimeout);
    }
};

var initdata = function(nodes,parent,level){
    for(var i=0;i<nodes.length;i++){
	var node = nodes[i];
	node.number = i;
	node.level = level;
	node.elder = (i > 0 ? nodes[i-1] : null);
	node.younger = (i < nodes.length-1 ? nodes[i+1] : null);
	node.parent = parent;
	if(node.children){
	    initdata(node.children,node,level+1);
	}
    }
};

var displine = function(text,level,y,color,bold,parent,showloading){
    var line;
    var x = 5 + level * 20;
    line = $('<span>');
    line.attr('class','line');
    line.css('width',String(Number(parent.css('width').replace(/px/,''))-x));
    line.css('left',String(x));
    line.css('color',color);
    line.css('top',String(y));
    if(bold) line.css('font-weight','bold');
    line.text('・' + text);
    if(showloading){
	// http://preloaders.net/ で作成したロード中アイコンを利用
	line.append($('<span>&nbsp;</span>'));
	line.append($('<img src="loading.gif" style="height:12pt;">'));
    }
    parent.append(line);
};

var display = function(){ // calc()で計算したリストを表示
    var body;
    var line;
    var node;
    var y;
    var i;
    var center = browserHeight() / 2;
    body = $('body');
    body.children().remove(); // 毎回富豪的にDOMを生成する

    if(list[0].url){
	win.location.href = list[0].url;
    }

    node = list[0];
    displine(node.title, node.level, center, '#00f', true, body, node.children);
    for(i=1;list[i];i++){
	y = center + i * 20;
	if(y > browserHeight() - 40) break;
	node = list[i];
	displine(node.title, node.level, y, '#000', false, body, false);
    }
    for(i= -1;list[i];i--){
	y = center + i * 20;
	if(y < 0) break;
	node = list[i];
	displine(node.title, node.level, y, '#000', false, body, false);
    }
};

var calc = function(centernode){ // centernodeを中心にlistを再計算して表示
    var node;
    var i;
    var newlist = {}; // 毎回富豪的にリストを生成
    newlist[0] = centernode;
    node = centernode;
    for(i=1;node = nextNode(node);i++){
	newlist[i] = node;
    }
    node = centernode;
    for(i= -1;node = prevNode(node);i--){
	newlist[i] = node;
    }
    list = newlist; // listからnewlistへの変化をアニメーションしたい
    display();
};

var nextNode = function(node){
    var nextnode = node.younger;
    while(!nextnode && node.parent){
	node = node.parent;
	nextnode = node.younger;
    }
    return nextnode;
};

var prevNode = function(node){
    var prevnode = node.elder;
    while(!prevnode && node.parent){
	prevnode = node.parent;
    }
    return prevnode;
};

$(window).keydown(function(e){
    clearTimeout(timeout);
    if(e.keyCode == 40 || e.keyCode == 39){ // 39 = 右, 40 = 下
	timeout = setTimeout(expand,ExpandTimeout);
	if(list[1]){
	    calc(list[1]);
	}
    }
    else if(e.keyCode == 38 || e.keyCode == 37){ // 37 = 左, 38 = 上
	timeout = setTimeout(expand,ExpandTimeout);
	if(list[-1]){
	    calc(list[-1]);
	}
    }
    return false;
});
