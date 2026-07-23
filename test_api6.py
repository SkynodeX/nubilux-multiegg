import urllib.request
req = urllib.request.Request("https://fill.papermc.io/v3/projects/paper/versions/26.1.2", headers={'User-Agent': 'Nubilux/1.0 (contact@nubilux.com)'})
try:
    with urllib.request.urlopen(req) as response:
        print(response.read().decode('utf-8'))
except Exception as e:
    print("Error:", e)
