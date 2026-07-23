#!/bin/bash
# Nubilux Custom Embedded Entrypoint

# Source all functions dynamically
for file in /functions/*.sh; do
    source "$file"
done

clear
echo -e "\e[31m  _   _       _     _ _            \e[0m"
echo -e "\e[33m | \ | |     | |   (_) |           \e[0m"
echo -e "\e[32m |  \| |_   _| |__  _| |_   ___  __\e[0m"
echo -e "\e[36m | . \` | | | | '_ \| | | | | \ \/ /\e[0m"
echo -e "\e[34m | |\  | |_| | |_) | | | |_| |>  < \e[0m"
echo -e "\e[35m |_| \_|\__,_|_.__/|_|_|\__,_/_/\_\ \e[0m"
echo -e "\e[1;36m=====================================\e[0m"
echo -e "\e[1;33m Welcome to Nubilux Hosting Multiegg!\e[0m"
echo -e "\e[1;36m=====================================\e[0m"

# Auto-migrate old loose dotfiles to hidden directory for cleaner file manager
if [ -f ".nubilux_installed" ]; then
    mkdir -p .cache/nubilux
    mv .nubilux_installed .cache/nubilux/.installed
    [ -f .mc_version ] && mv .mc_version .cache/nubilux/mc_version
    [ -f .mc_choice ] && mv .mc_choice .cache/nubilux/mc_choice
    [ -f .mc_build ] && mv .mc_build .cache/nubilux/mc_build
fi

# Check if environment is already configured
if [ -f ".cache/nubilux/.installed" ]; then
    echo -e "\e[32m[+] Server already configured. Booting...\e[0m"
    
    # Check what type of server it is
    if [ -f "bedrock_server" ]; then
        boot_bedrock
    elif [ -f "server.jar" ]; then
        boot_minecraft
    elif [ -f "package.json" ] || [ -f "index.js" ] || [ -f "main.js" ]; then
        boot_nodejs
    elif [ -f "main.py" ] || [ -f "bot.py" ] || [ -f "requirements.txt" ]; then
        boot_python
    else
        echo -e "\e[31m[!] Cannot determine server type. Missing server files (e.g. server.jar).\e[0m"
        echo -e "\e[33m[~] It looks like you wiped your server files. Resetting configuration for a fresh install...\e[0m"
        rm -rf .nubilux
        rm -f .nubilux_installed
        exec /bin/bash /entrypoint.sh
    fi
else
    # Interactive Setup Menu
    while true; do
        echo ""
        echo "Please select what type of server you want to install:"
        echo -e "\e[32m1)\e[0m Minecraft: Java Edition (Paper, Purpur, Vanilla)"
        echo -e "\e[32m2)\e[0m NodeJS Discord Bot (discord.js)"
        echo -e "\e[32m3)\e[0m Python Discord Bot (discord.py)"
        echo -e "\e[32m4)\e[0m Minecraft: Bedrock Edition"
        echo -e "\e[31m5)\e[0m Exit Installer"
        echo ""
        echo "Your choice (1-5): "
        read choice
        
        case $choice in
            1)
                minecraft_menu
                break
                ;;
            2)
                nodejs_menu
                break
                ;;
            3)
                python_menu
                break
                ;;
            4)
                bedrock_menu
                break
                ;;
            5)
                exit 0
                ;;
            *)
                echo -e "\e[31m[!] Invalid choice.\e[0m"
                sleep 1
                ;;
        esac
    done
fi
