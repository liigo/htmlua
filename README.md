html
====

Lua's C module for parsing html text, wrapper of liigo::HtmlParser

LUA的HTML解析库，C模块，封装自C++的库[liigo::HtmlParser](https://github.com/liigo/html-parser)。

###〇、基本概念

本HTML解析器把HTML文本解析为一组有序的节点(Node)。各节点分为不同的类型，记录了不同的信息。
节点的类型有：开始标签（如&lt;a href="..."&gt;）、结束标签（如&lt;/a&gt;）、文本、注释等。
开始标签和结束标签都有一个标签名称（tagname，如上例的"a"），相应的有一个标签类型（tagtype，用整数标识标签）。
仅在必要的情况下，才把标签名称识别为标签类型，主要目的是提高解析速度。这一操作是用户可控的。
开始标签节点往往有一系列属性（Attributes，如前例中的"href"）。默认情况下，仅对已识别出标签类型的节点才解析其属性。

本文第四节将专门介绍节点类型和标签类型。更多信息请参考[我CSDN博客上的文章](http://blog.csdn.net/liigo/article/details/6153829)。

###一、加载html库，创建parser解析器对象

	local html = require "html"

该html对象（可自由命名）有以下两个函数：

	html.newparser(fn1,fn2)   -- 创建解析器对象，两参数均可省略（详见下文第五节），返回parser
	html.deleteparser(parser) -- 删除解析器对象，参数为parser，无返回值

该html对象还有一个自动创建好的 parser 成员，可供直接使用，无需显式创建和删除。

###二、parser解析器对象，解析HTML文本

parser解析器有以下方法（需首先传入parser自身）：

	parser:parse(html) -- 解析HTML文本，参数是HTML文本，无返回值
	parser:nodecount() -- 返回解析后的节点个数
	parser:node(index) -- 返回解析后的指定索引处的节点对象，参数是节点索引(>=1,<=nodecount())，返回值是node对象（可能为nil）
	parser:ipairs()    -- 用于支持for循环顺序遍历节点，如：for index,node in parser:ipairs() do ...

借助于 parser:ipairs() 方法，可以用 for 循环顺序遍历 node 节点对象：

	parser:parse("<html><body bg=red id=liigo>xxx<p x=123>...")
	for index,node in parser:ipairs() do
		print("node:", index, node.tagname, node.text)
	end

###三、node节点对象，获取节点信息

node对象有以下成员：

	node.type      -- 节点类型（int）
	node.text      -- 节点文本（string）
	node.tagname   -- 标签名称（string）
	node.tagtype   -- 标签类型（int）
	node.attrcount -- 属性个数（int）
	node.iscdata   -- 是否CDATA区块（bool）
	node.isselfclosing -- 是否自结束标签（bool）（例如<br/>为自结束标签）

node对象有以下方法（需首先传入parser自身）：

	node:attr(index/name) -- 取指定属性值。如果参数是属性名(string)，返回属性值(string)；如果参数是属性索引(>=1,<=attrcount)，返回属性名(string)和属性值(string)；如果参数指定的属性不存在，返回两个nil。
	node:pairs()     -- 用于支持for循环遍历属性，如 for name,value in node:pairs() do ...
	node:parseattr() -- 无参数无返回值，解析结果存入node对象中。如果先前已经解析过，不会重复解析。本库会自动解析已确定标签类型的节点属性。

借助于 node:pairs() 方法，可以用 for 循环遍历节点属性：

	local node1 = parser:node(1)
	for name,value in node1:pairs() do
		print("attr:", name, value)
	end

注意，操作node的过程中需保证parser对象始终有效，且没有调用parser:parse()执行下一次解析。

###四、节点类型和标签类型

节点类型用一个整数来表示，定义如下：

	--定义节点(Node)类型
	local htmlnode = {
		NULL      = 0, --作为所有节点的终结标记（LUA中未用到）
		START_TAG = 1, --开始标签，如 <a href="liigo.com"> 或 <br/>
		END_TAG   = 2, --结束标签，如 </a>
		CONTENT   = 3, --内容: 介于开始标签和/或结束标签之间的普通文本
		REMARKS   = 4, --注释: <!-- -->
		UNKNOWN   = 5, --未知的节点类型
		_USER_ = 10, --用户定义的其他节点类型值应大于_USER_，以确保不与上面定义的常量值重复
	}

考虑到不想污染LUA全局变量，没有把它定义在C模块中。用户需要在程序中自行定义节点类型常量，通常复制以上代码即可。使用方法： if(nodetype == htmlnode.START_TAG) ...

标签类型也用一个整数来表示，定义如下：

	--定义标签(Tag)类型
	local htmltag = {
		UNKNOWN = 0, --表示未经识别的标签类型，参见HtmlParser.onIdentifyHtmlTag()
		SCRIPT=1, STYLE=2, TEXTAREA=3, --出于解析需要必须识别<script>,<style>和<textarea>，内部特别处理
		--以下按标签字母顺序排列, 来源：http://www.w3.org/TR/html4/index/elements.html (HTML4)
		--还有 http://www.w3.org/TR/html5/section-index.html#elements-1 (HTML5)
		A=101, ABBR=102, ACRONYM=103, ADDRESS=104, APPLET=105, AREA=106, ARTICLE=107, ASIDE=108, AUDIO=109,
		B=110, BASE=111, BASEFONT=112, BDI=113, BDO=114, BIG=115, BLOCKQUOTE=116, BODY=117, BR=118, BUTTON=119,
		CAPTION=120, CENTER=121, CITE=122, CODE=123, COL=124, COLGROUP=125, COMMAND=126,
		DATALIST=127, DD=128, DEL=129, DETAILS=130, DFN=131, DIR=132, DIV=133, DL=134, DT=135, EM=136, EMBED=137,
		FIELDSET=138, FIGCAPTION=139, FIGURE=140, FONT=141, FOOTER=142, FORM=143, FRAME=144, FRAMESET=145,
		H1=146, H2=147, H3=148, H4=149, H5=150, H6=151, HEAD=152, HEADER=153, HGROUP=154, HR=155, HTML=156,
		I=157, IFRAME=158, IMG=159, INPUT=160, INS=161, ISINDEX=162, KBD=163, KEYGEN=164,
		LABEL=165, LEGEND=166, LI=167, LINK=168, MAP=169, MARK=170, MENU=171, META=172, METER=173, NAV=174, NOFRAMES=175, NOSCRIPT=176,
		OBJECT=177, OL=178, OPTGROUP=179, OPTION=180, P=181, PARAM=182, PRE=183, PROGRESS=184, Q=185, RP=186, RT=187, RUBY=188,
		S=189, SAMP=190, SECTION=191, SELECT=192, SMALL=193, SOURCE=194, SPAN=195, STRIKE=196, STRONG=197, SUB=198, SUMMARY=199, SUP=200,
		TABLE=201, TBODY=202, TD=203, TFOOT=204, TH=205, THEAD=206, TIME=207, TITLE=208, TR=209, TRACK=210, TT=211,
		U=212, UL=213, VAR=214, VIDEO=215, WBR=216,
		_USER_=300, --用户定义的其他标签类型值应大于_USER_，以确保不与上面定义的常量值重复
	}

考虑到不想污染LUA全局变量，没有把它定义在C模块中。况且多少情况下没有必要识别那么多标签类型，用户可根据情况自行确定要识别的标签，在程序中自行定义节点类型常量，通常复制以上代码即可。使用方法： if(tagtype == htmltag.DIV) ...

TODO(liigo): 把以上常量定义到C模块中！以方便用户使用为主要出发点。况且LUA的table是哈希表，从标签名称查询标签类型，基本上不影响解析速度。相应地还在考虑要不要删除回调fnIdentifyHtmlTag、增加回调onParseAttributes。

###五、parser解析器的回调函数

函数 html.newparser() 有两个可省略的参数，可接收两个函数作为回调函数，它们在解析过程中被调用，其原型如下：

	function fnIdentifyHtmlTag (tagname, nodetype) number
	function fnOnNodeReady (node) bool

回调函数 fnIdentifyHtmlTag 在解析到开始标签和结束标签时被调用，用于识别该标签名称对应的标签类型。它的两个参数分别是标签名称tagname（文本）和节点类型nodetype（整数），返回值是标签类型tagtype（整数）。识别的标签越少，解析速度越快。出于解析速度的考虑，除非必要，无需识别标签类型。只有确定了标签类型的标签，其属性才会被自动解析，否则只能手工解析（见node:parseattr()）。

回调函数 fnOnNodeReady 在解析完成每个节点后被调用，用户可在此确定是否继续解析。它的参数是节点对象node，返回值是bool。返回true表示继续解析，返回false表示终止解析。

本库的测试例程 test.lua 中有使用这两个回调函数的示例，基本代码如下：

	local htmltag = {
		UNKNOWN = 0, SCRIPT=1, STYLE=2, TEXTAREA=3, 
		A=101, DIV=... IMG=... …………
	}

	local function identifyHtmlTag(tagname, nodetype)
		--print("identifyHtmlTag:", tagname, nodetype)
		return htmltag[string.upper(tagname)] or htmltag.UNKNOWN
	end

	local function onNodeReady(node)
		--print("onnodeready:", node.tagname, node.text)
		return (node.tagname ~= "break")
	end

	local parser = html.newparser(identifyHtmlTag, onNodeReady)
