import urllib.request
import json
req = urllib.request.Request("https://api.papermc.io/v2/projects/paper/versions/1.21.1", headers={'User-Agent': 'Nubilux/1.0'})
try:
    with urllib.request.urlopen(req) as response:
        print(response.read().decode('utf-8'))
except Exception as e:
    print(e)
