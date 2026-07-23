import zipfile, sys
try:
    with zipfile.ZipFile('paper.jar', 'r') as z:
        for name in z.namelist():
            if name.startswith('META-INF/versions/') and name.endswith('.jar'):
                with z.open(name) as inner:
                    inner_bytes = inner.read()
                    import io
                    with zipfile.ZipFile(io.BytesIO(inner_bytes), 'r') as inner_z:
                        manifest = inner_z.read('META-INF/MANIFEST.MF').decode('utf-8')
                        main_class = next((line.split(':')[1].strip().replace('.', '/') + '.class' for line in manifest.splitlines() if line.startswith('Main-Class:')), None)
                        if main_class and main_class in inner_z.namelist():
                            major = inner_z.read(main_class)[7]
                            print('Inner major: ' + str(major))
                            sys.exit(0)
except Exception as e:
    print(e)
