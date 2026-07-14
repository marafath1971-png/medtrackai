import re

with open('lib/screens/home/home_tab.dart', 'r') as f:
    content = f.read()

content = content.replace("size: 88,", "size: 64,")
content = content.replace("strokeWidth: 9,", "strokeWidth: 6,")
content = content.replace("fontSize: 22,", "fontSize: 16,")

with open('lib/screens/home/home_tab.dart', 'w') as f:
    f.write(content)

