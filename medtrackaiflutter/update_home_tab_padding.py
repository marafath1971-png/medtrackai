import re

with open('lib/screens/home/home_tab.dart', 'r') as f:
    content = f.read()

content = content.replace(
    "padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)",
    "padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)"
)
content = content.replace(
    "fontSize: 14,",
    "fontSize: 13,"
)
content = content.replace(
    "padding: const EdgeInsets.only(top: 16, bottom: 8),",
    "padding: const EdgeInsets.only(top: 8, bottom: 8),"
)

with open('lib/screens/home/home_tab.dart', 'w') as f:
    f.write(content)

