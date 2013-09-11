html
====

Lua's C module for parsing html text, wrapper of liigo::HtmlParser

LUA的HTML解析库，C模块，封装自C++的库[liigo::HtmlParser](https://github.com/liigo/html-parser)。

###〇、基本概念

本HTML解析器把HTML文本解析为一组有序的节点(Node)。各节点分为不同的类型，记录了不同的信息。
节点的类型有：开始标签（如&lt;a href="..."&gt;）、结束标签（如&lt;/a&gt;）、文本、注释等。
开始标签和结束标签都有一个标签名称（tagname,如上例的"a"），相应的有一个标签类型（tagtype,用整数标识标签）。
仅在必要的情况下，才把标签名称识别为标签类型，主要目的是提高解析速度。这一操作是用户可控的。
开始标签节点往往有一系列属性（Attributes,如前例中的"href"）。默认情况下，仅对已识别出标签类型的节点才解析其属性。

更多信息请参考[我CSDN博客上的介绍文章](http://blog.csdn.net/liigo/article/details/6153829)。

###一、加载html库，创建parser解析器对象

	local html = require "html"

该html对象（可自由命名）有以下两个函数：

	html.newparser(fnIdentifyHtmlTag) -- 创建解析器对象，参数可省略(见下文)，返回parser
	html.deleteparser(parser)         -- 删除解析器对象，参数为parser，无返回值

该html对象还有一个自动创建好的 parser 成员，可供直接使用，无需显式创建和删除。

html.newparser的可选参数的函数原型是 int fnIdentifyHtmlTag(string, int)。
该函数的参数是标签名称tagname（文本）和节点类型nodetype（整数），返回值是tagtype（整数）。
该函数的功能是，根据传入的标签名称确定标签类型并返回。
识别的标签越少，解析速度越快。只有确定了标签类型的标签，其属性才会被自动解析，否则只能手工解析（见node:parseattr()）。
出于解析速度的考虑，除非必要，无需识别标签类型。
本库的测试例程 test.lua 中有使用该函数的示例，基本代码如下：

	local htmltag = {
		UNKNOWN = 0, SCRIPT=1, STYLE=2, TEXTAREA=3, 
		A=101, DIV=... IMG=... …………
	}

	local function identifyHtmlTag(tagname, nodetype)
		return htmltag[string.upper(tagname)] or htmltag.UNKNOWN
	end

	local parser = html.newparser(identifyHtmlTag)

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
