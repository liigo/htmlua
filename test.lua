local html = require "htmlua"

local parser = html.newparser()
parser:parse("<html><body bg=red id=liigo>xxx<p x=123>...")

for index,node in parser:ipairs() do
	print(index, node.tagname, node.text)
end

local node = parser:node(2)
print(node.tagname, node.text, node.attrcount)
print(node:attr("bg"), node:attr("id"), node:attr("nothisattr"))

html.deleteparser(parser)

local function testNodes()
	print("------Test Nodes------")
	local parser = html.newparser()
	parser:parse("<body>000<a>111</a><BR/>")
	assert(parser:nodecount() == 6)
	for index,node in parser:ipairs() do
		print("node:", index, node.tagname, node.text)
	end

	local node1 = parser:node(1)
	assert(node1.type == htmlnode.START_TAG)
	assert(node1.tagname == "body");
	assert(node1.tagtype == htmltag.BODY)
	assert(node1.text == "")
	assert(node1.attrcount == 0)

	assert(parser:node(2).text == "000")
	assert(parser:node(2).tagtype == htmltag.UNKNOWN)
	assert(parser:node(3).tagtype == htmltag.A)
	assert(parser:node(5).tagtype == htmltag.A)
	assert(parser:node(6).tagtype == htmltag.BR)
	assert(parser:node(0) == nil and parser:node(10) == nil) -- no such node

	html.deleteparser(parser)
end

local function testNodeAttributes()
	print("------Test attributes------")
	local parser = html.newparser()
	parser:parse("<a href='liigo.com' color=red checked>111</a>")
	assert(parser:nodecount() == 3)
	local node1 = parser:node(1)
	assert(node1 ~= nil)
	assert(node1.attrcount == 3) --count of attributes
	for name,value in node1:pairs() do
		print("attr: ", name, value)
	end
	--get attribute value by name
	assert(node1:attr("href") == "liigo.com")
	assert(node1:attr("color") == "red")
	assert(node1:attr("checked") == "")
	assert(node1:attr("nosuchattr") == nil)
	--get attribute name and value by index
	local n1,v1 = node1:attr(1)
	assert(n1 == "href" and v1 == "liigo.com")
	local n2,v2 = node1:attr(2)
	assert(n2 == "color" and v2 == "red")
	local n3,v3 = node1:attr(3)
	assert(n3 == "checked" and v3 == "") --value is "" not nil
	local n4,v4 = node1:attr(4)
	assert(n4 == nil and v4 == nil) --no such attribute
	html.deleteparser(parser)
end

local function onParseAttr(node)
	print("onParseAttr:", node.tagname, node.text)
	return (node.tagname == "2")
end

local function onNodeReady(node)
	print("onNodeReady:", node.tagname, node.text)
	return (node.tagname ~= "break")
end

local function testParserCallbacks()
	print("------Test Callbacks------")
	local parser = html.newparser(onParseAttr, onNodeReady)
	parser:parse("<1 a=b><2 x=y><3>...<5 x=0><break><7><8>")
	assert(parser:node(1).attrcount == 0) --未解析其属性,参见onParseAttr()
	assert(parser:node(2).attrcount == 1)
	assert(parser:node(5).attrcount == 0)
	assert(parser:node(7) == nil) --在<break>处就已经终止解析,参见onNodeReady()
	html.deleteparser(parser)
end

testNodes()
testNodeAttributes()
testParserCallbacks()

print("test htmlua over")
