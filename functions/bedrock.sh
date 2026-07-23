function bedrock_menu {
    mkdir -p .cache/nubilux
    echo ""
    echo -e "\e[36m[~] Fetching latest Bedrock Server version from Microsoft...\e[0m"
    
    # Scrape the official download URL
    URL=$(curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -sL https://www.minecraft.net/en-us/download/server/bedrock | grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*')
    
    if [ -z "$URL" ]; then
        echo -e "\e[31m[!] Failed to fetch Bedrock URL from Microsoft's website. Please check later.\e[0m"
        exit 1
    fi
    
    echo -e "\e[36m[~] Downloading $URL ...\e[0m"
    curl -o bedrock_server.zip "$URL"
    
    echo -e "\e[36m[~] Extracting files...\e[0m"
    unzip -o bedrock_server.zip
    rm bedrock_server.zip
    
    # Make the binary executable
    chmod +x bedrock_server
    
    touch .cache/nubilux/.installed
    echo -e "\e[32m[+] Bedrock installation complete! Restarting server...\e[0m"
    exec /bin/bash /entrypoint.sh
}

function boot_bedrock {
    echo -e "\e[32m[+] Starting Minecraft Bedrock Dedicated Server...\e[0m"
    export LD_LIBRARY_PATH=.
    exec ./bedrock_server
}
