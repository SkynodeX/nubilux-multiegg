#!/bin/bash
# Discord Bots functionality (NodeJS & Python)

function nodejs_menu {
    mkdir -p .cache/nubilux
    echo ""
    echo -e "\e[36m[~] Setting up NodeJS Environment...\e[0m"
    
    if [ ! -f "package.json" ]; then
        echo '{"name": "discord-bot","version": "1.0.0","main": "index.js","scripts": {"start": "node index.js"}}' > package.json
    fi
    if [ ! -f "index.js" ]; then
        echo 'console.log("Hello from NodeJS! Please upload your bot files.");' > index.js
    fi
    
    touch .cache/nubilux/.installed
    echo -e "\e[32m[+] NodeJS environment ready. Please upload your bot files to the server.\e[0m"
    exec /bin/bash /entrypoint.sh
}

function python_menu {
    mkdir -p .cache/nubilux
    echo ""
    echo -e "\e[36m[~] Setting up Python Environment...\e[0m"
    
    if [ ! -f "main.py" ]; then
        echo 'print("Hello from Python! Please upload your bot files.")' > main.py
    fi
    if [ ! -f "requirements.txt" ]; then
        touch requirements.txt
    fi
    echo "Would you like to install discord.py boilerplate? (y/n): "
    read install_boilerplate
    touch .cache/nubilux/.installed
    echo -e "\e[32m[+] Python environment ready. Please upload your bot files to the server.\e[0m"
    exec /bin/bash /entrypoint.sh
}

function boot_nodejs {
    echo -e "\e[32m[+] Starting NodeJS App...\e[0m"
    
    if [ -f "package.json" ]; then
        echo -e "\e[36m[~] Installing npm dependencies...\e[0m"
        npm install --production --silent
        
        # Check if there is a start script
        if grep -q '"start"' package.json; then
            exec npm start
        else
            if [ -f "index.js" ]; then exec node index.js; fi
            if [ -f "main.js" ]; then exec node main.js; fi
        fi
    else
        if [ -f "index.js" ]; then exec node index.js; fi
        if [ -f "main.js" ]; then exec node main.js; fi
    fi
}

function boot_python {
    echo -e "\e[32m[+] Starting Python App...\e[0m"
    
    if [ -f "requirements.txt" ]; then
        echo -e "\e[36m[~] Installing python dependencies...\e[0m"
        pip3 install -r requirements.txt --quiet
    fi
    
    if [ -f "main.py" ]; then
        exec python3 main.py
    elif [ -f "bot.py" ]; then
        exec python3 bot.py
    else
        echo -e "\e[31m[!] No main.py or bot.py found.\e[0m"
        exit 1
    fi
}
