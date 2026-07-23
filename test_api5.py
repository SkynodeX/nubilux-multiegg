import urllib.request
req = urllib.request.Request("https://fill.papermc.io/v3/projects/velocity/versions/3.3.0-SNAPSHOT/builds/436", headers={'User-Agent': 'Nubilux/1.0 (contact@nubilux.com)'})
try:
    with urllib.request.urlopen(req) as response:
        print(response.read().decode('utf-8'))
except Exception as e:
    print("Error:", e)
