f = open("README.md", "r", encoding="utf-8")
content = f.read()
f.close()
string_list = content.split("\n")
outputlist = []
for i in string_list:
    outputstring = i
    hashindex = 0
    while len(i) > hashindex and i[hashindex] == "#":
        hashindex += 1
    if hashindex > 0:
        outputstring = "[h{0}]{1}[/h{0}]".format(hashindex, outputstring[hashindex + 1:])
    outputstring = outputstring.replace("```lua","[code]")
    outputstring = outputstring.replace("```","[/code]")
    outputstring = outputstring.replace("`","\"")
    while "**" in outputstring:
        outputstring = outputstring.replace("**", "[b]",1)
        outputstring = outputstring.replace("**", "[/b]",1)
    outputlist.append(outputstring)
f = open("STEAM_DESC.txt", "w", encoding = "utf-8")
f.write("\n".join(outputlist))
