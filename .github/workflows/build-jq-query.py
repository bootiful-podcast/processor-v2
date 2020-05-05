#!/usr/bin/env python
import sys

s = '''
 .[] | map(select (.GroupName == "%s") ) | .[0].GroupName ' ) 
'''.strip() % sys.argv[1].strip()
print(s)
