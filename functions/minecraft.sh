#!/bin/bash
# Minecraft specific functions

function accept_eula {
    echo "eula=true" > eula.txt
}

function handle_optimization {
    if [ "$OPTIMIZE_SERVER" == "1" ]; then
        echo -e "\e[36m[~] Auto-optimizing server properties for EXTREME performance...\e[0m"
        # If server.properties doesn't exist, create it
        if [ ! -f "server.properties" ]; then
            touch server.properties
        fi
        
        # Aggressive View & Simulation distances (ENFORCED ON EVERY BOOT)
        sed -i '/^view-distance=/d' server.properties
        echo "view-distance=4" >> server.properties
        
        sed -i '/^simulation-distance=/d' server.properties
        echo "simulation-distance=3" >> server.properties
        
        sed -i '/^network-compression-threshold=/d' server.properties
        echo "network-compression-threshold=256" >> server.properties
        
        # Inject or OVERRIDE extreme spigot.yml base optimization
        if [ ! -f "spigot.yml" ]; then
            echo "world-settings:" > spigot.yml
            echo "  default:" >> spigot.yml
            echo "    entity-activation-range:" >> spigot.yml
            echo "      animals: 16" >> spigot.yml
            echo "      monsters: 24" >> spigot.yml
            echo "      misc: 8" >> spigot.yml
            echo "      tick-inactive-villagers: false" >> spigot.yml
        else
            # Forcefully overwrite values in existing spigot.yml (in case they uploaded a setup)
            python3 -c "
import re
try:
    with open('spigot.yml', 'r') as f: content = f.read()
    content = re.sub(r'animals:\s*\d+', 'animals: 16', content)
    content = re.sub(r'monsters:\s*\d+', 'monsters: 24', content)
    content = re.sub(r'misc:\s*\d+', 'misc: 8', content)
    content = re.sub(r'tick-inactive-villagers:\s*(true|false)', 'tick-inactive-villagers: false', content)
    with open('spigot.yml', 'w') as f: f.write(content)
except: pass
"
        fi
        
        echo -e "\e[32m[+] Extreme Optimization applied and ENFORCED.\e[0m"
    fi
}

function handle_motd {
    if [ -n "$HOSTING_NAME" ]; then
        echo -e "\e[36m[~] Injecting Forced Branding MOTD...\e[0m"
        if [ ! -f "server.properties" ]; then
            touch server.properties
        fi
        
        # Remove existing motd and append ours
        sed -i '/^motd=/d' server.properties
        echo "motd=Powered by $HOSTING_NAME" >> server.properties
    fi
}

function minecraft_menu {
    echo ""
    echo "Choose your Minecraft Software:"
    echo "1) Paper (Standard Server)"
    echo "2) Purpur (Standard Server)"
    echo "3) Vanilla (Standard Server)"
    echo "4) Velocity (Proxy)"
    echo "5) BungeeCord (Proxy)"
    read -p "Choice (1-5): " mc_choice
    
    if [ "$mc_choice" != "5" ]; then
        read -p "Enter Version (e.g., 1.20.4, 1.8.8, or 3.3.0 for Velocity): " version
    fi
    
    case $mc_choice in
        1)
            # Fetch paper
            build=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$version" | jq -r '.builds[-1]')
            url="https://api.papermc.io/v2/projects/paper/versions/${version}/builds/${build}/downloads/paper-${version}-${build}.jar"
            curl -o server.jar "$url"
            ;;
        2)
            url="https://api.purpurmc.org/v2/purpur/${version}/latest/download"
            curl -o server.jar "$url"
            ;;
        3)
            manifest_url=$(curl -s "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r --arg VERSION "$version" '.versions[] | select(.id == $VERSION) | .url')
            server_url=$(curl -s "$manifest_url" | jq -r '.downloads.server.url')
            curl -o server.jar "$server_url"
            ;;
        4)
            # Fetch velocity
            build=$(curl -s "https://api.papermc.io/v2/projects/velocity/versions/$version" | jq -r '.builds[-1]')
            url="https://api.papermc.io/v2/projects/velocity/versions/${version}/builds/${build}/downloads/velocity-${version}-${build}.jar"
            curl -o server.jar "$url"
            ;;
        5)
            # Fetch latest bungeecord
            url="https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar"
            curl -o server.jar "$url"
            ;;
        *)
            echo "Invalid choice. Aborting."
            exit 1
            ;;
    esac
    
    accept_eula
    touch .nubilux_installed
    echo -e "\e[32m[+] Minecraft installation complete! Restarting server...\e[0m"
    exec /bin/bash /entrypoint.sh
}

function boot_minecraft {
    handle_optimization
    handle_motd

    MEM_ARG=""
    if [ -n "$SERVER_MEMORY" ] && [ "$SERVER_MEMORY" != "0" ]; then
        MEM_ARG="-Xmx${SERVER_MEMORY}M -Xms128M"
    fi
    
    SIMD_ARG=""
    if [ "$SIMD_OPERATIONS" == "1" ]; then
        SIMD_ARG="--add-modules=jdk.incubator.vector"
    fi
    
    JAVA_CMD="java"
    # Base Aikar Flags
    GC_FLAGS="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
    
    if [ "$JAVA_VERSION" == "21" ]; then 
        JAVA_CMD="/usr/lib/jvm/java-21-openjdk-amd64/bin/java"
        if [ "$OPTIMIZE_SERVER" == "1" ]; then
            # EXTREME ZGC for Java 21 (Valorant Tier Zero-Lag Spikes)
            GC_FLAGS="-XX:+UseZGC -XX:+ZGenerational"
        fi
    fi
    if [ "$JAVA_VERSION" == "17" ]; then JAVA_CMD="/usr/lib/jvm/java-17-openjdk-amd64/bin/java"; fi
    if [ "$JAVA_VERSION" == "11" ]; then JAVA_CMD="/usr/lib/jvm/java-11-openjdk-amd64/bin/java"; fi
    if [ "$JAVA_VERSION" == "8" ];  then JAVA_CMD="/usr/lib/jvm/java-8-openjdk-amd64/bin/java";  fi

    echo -e "\e[32m[+] Starting Minecraft Server with $JAVA_CMD...\e[0m"
    exec $JAVA_CMD $MEM_ARG $SIMD_ARG $GC_FLAGS -jar server.jar nogui
}
