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
    mkdir -p .cache/nubilux
    echo ""
    echo "Choose your Minecraft Software:"
    echo "1) Paper (Standard Server)"
    echo "2) Purpur (Standard Server)"
    echo "3) Vanilla (Standard Server)"
    echo "4) Velocity (Proxy)"
    echo "5) BungeeCord (Proxy)"
    echo "Choice (1-5): "
    read mc_choice
    
    if [ "$mc_choice" != "5" ]; then
        echo "Enter Version (e.g., 1.20.4, 1.8.8, or 3.3.0 for Velocity): "
        read version
    fi
    
    case $mc_choice in
        1)
            # Fetch paper
            build=$(curl -s -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" "https://fill.papermc.io/v3/projects/paper/versions/$version" | jq -r '.builds[0]')
            url=$(curl -s -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" "https://fill.papermc.io/v3/projects/paper/versions/${version}/builds/${build}" | jq -r '.downloads["server:default"].url')
            curl -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" -o server.jar "$url"
            echo "$build" > .cache/nubilux/mc_build
            ;;
        2)
            build=$(curl -s "https://api.purpurmc.org/v2/purpur/$version" | jq -r '.builds.latest')
            url="https://api.purpurmc.org/v2/purpur/${version}/latest/download"
            curl -o server.jar "$url"
            echo "$build" > .cache/nubilux/mc_build
            ;;
        3)
            manifest_url=$(curl -s "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r --arg VERSION "$version" '.versions[] | select(.id == $VERSION) | .url')
            server_url=$(curl -s "$manifest_url" | jq -r '.downloads.server.url')
            curl -o server.jar "$server_url"
            ;;
        4)
            # Fetch velocity
            build=$(curl -s -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" "https://fill.papermc.io/v3/projects/velocity/versions/$version" | jq -r '.builds[0]')
            url=$(curl -s -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" "https://fill.papermc.io/v3/projects/velocity/versions/${version}/builds/${build}" | jq -r '.downloads["server:default"].url')
            curl -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" -o server.jar "$url"
            echo "$build" > .cache/nubilux/mc_build
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
    
    # Verify the download succeeded (file exists and is > 1MB roughly, or just > 100KB)
    # A corrupt jar or 404 page is usually very small.
    if [ ! -f "server.jar" ] || [ $(stat -c%s "server.jar") -lt 1000000 ]; then
        echo -e "\e[31m[!] Failed to download the server software. The version might be invalid.\e[0m"
        rm -f server.jar
        exit 1
    fi
    
    accept_eula
    echo "$version" > .cache/nubilux/mc_version
    echo "$mc_choice" > .cache/nubilux/mc_choice
    touch .cache/nubilux/.installed
    echo -e "\e[32m[+] Minecraft installation complete! Restarting server...\e[0m"
    exec /bin/bash /entrypoint.sh
}

function auto_update {
    if [ "$AUTO_UPDATE" == "1" ] && [ -f ".cache/nubilux/mc_version" ] && [ -f ".cache/nubilux/mc_choice" ]; then
        mc_choice=$(cat .cache/nubilux/mc_choice)
        version=$(cat .cache/nubilux/mc_version)
        current_build=""
        if [ -f ".cache/nubilux/mc_build" ]; then
            current_build=$(cat .cache/nubilux/mc_build)
        fi
        
        echo -e "\e[36m[~] Auto-Update is enabled! Checking for updates...\e[0m"
        case $mc_choice in
            1)
                build=$(curl -s -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" "https://fill.papermc.io/v3/projects/paper/versions/$version" | jq -r '.builds[0]')
                if [ -n "$build" ] && [ "$build" != "null" ]; then
                    if [ "$build" != "$current_build" ]; then
                        echo -e "\e[36m[~] Updating Paper from build $current_build to $build...\e[0m"
                        url=$(curl -s -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" "https://fill.papermc.io/v3/projects/paper/versions/${version}/builds/${build}" | jq -r '.downloads["server:default"].url')
                        curl -s -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" -o server.jar "$url"
                        echo "$build" > .cache/nubilux/mc_build
                        echo -e "\e[32m[+] Successfully updated Paper!\e[0m"
                    else
                        echo -e "\e[32m[+] Server is already on the latest build ($build)!\e[0m"
                    fi
                fi
                ;;
            2)
                build=$(curl -s "https://api.purpurmc.org/v2/purpur/$version" | jq -r '.builds.latest')
                if [ -n "$build" ] && [ "$build" != "null" ]; then
                    if [ "$build" != "$current_build" ]; then
                        echo -e "\e[36m[~] Updating Purpur to build $build...\e[0m"
                        url="https://api.purpurmc.org/v2/purpur/${version}/latest/download"
                        curl -s -o server.jar "$url"
                        echo "$build" > .cache/nubilux/mc_build
                        echo -e "\e[32m[+] Successfully updated Purpur!\e[0m"
                    else
                        echo -e "\e[32m[+] Server is already on the latest build ($build)!\e[0m"
                    fi
                fi
                ;;
            4)
                build=$(curl -s -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" "https://fill.papermc.io/v3/projects/velocity/versions/$version" | jq -r '.builds[0]')
                if [ -n "$build" ] && [ "$build" != "null" ]; then
                    if [ "$build" != "$current_build" ]; then
                        echo -e "\e[36m[~] Updating Velocity from build $current_build to $build...\e[0m"
                        url=$(curl -s -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" "https://fill.papermc.io/v3/projects/velocity/versions/${version}/builds/${build}" | jq -r '.downloads["server:default"].url')
                        curl -s -A "NubiluxMultiegg/1.0 (admin@nubilux.com)" -o server.jar "$url"
                        echo "$build" > .cache/nubilux/mc_build
                        echo -e "\e[32m[+] Successfully updated Velocity!\e[0m"
                    else
                        echo -e "\e[32m[+] Server is already on the latest build ($build)!\e[0m"
                    fi
                fi
                ;;
        esac
    fi
}

function boot_minecraft {
    if [ -f .cache/nubilux/mc_version ]; then
        version=$(cat .cache/nubilux/mc_version)
    fi
    
    auto_update
    
    handle_optimization
    handle_motd

    MEM_ARG=""
    if [ -n "$SERVER_MEMORY" ] && [ "$SERVER_MEMORY" != "0" ]; then
        MEM_ARG="-Xmx${SERVER_MEMORY}M -Xms128M"
    fi
    
    JAVA_CMD="java"
    # Base Aikar Flags + Log4Shell Protection for older versions
    GC_FLAGS="-Dlog4j2.formatMsgNoLookups=true -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
      # Try to read version.json first (best for Paperclip/Vanilla jars where bootstrapper class version differs from actual server)
      version_id=$(unzip -p server.jar version.json 2>/dev/null | grep -o '"id": *"[^"]*"' | cut -d'"' -f4)
      
      detected_java="unknown"
      if [[ "$version_id" == 1.21.2* ]] || [[ "$version_id" == 1.21.3* ]] || [[ "$version_id" == 26* ]] || [[ "$version_id" == 27* ]]; then
          detected_java="25"
      elif [[ "$version_id" == 1.20.5* ]] || [[ "$version_id" == 1.20.6* ]] || [[ "$version_id" == 1.21* ]]; then
          detected_java="21"
      elif [[ "$version_id" == 1.17* ]] || [[ "$version_id" == 1.18* ]] || [[ "$version_id" == 1.19* ]] || [[ "$version_id" == 1.20* ]]; then
          detected_java="17"
      elif [[ -n "$version_id" ]]; then
          # Older known version detected
          detected_java="11"
      else
          # Fallback to python class version detection if version.json is missing
          detected_java=$(python3 -c '
import zipfile, sys
try:
    with zipfile.ZipFile("server.jar", "r") as z:
        manifest = z.read("META-INF/MANIFEST.MF").decode("utf-8")
        main_class = next((line.split(":")[1].strip().replace(".", "/") + ".class" for line in manifest.splitlines() if line.startswith("Main-Class:")), None)
        if main_class and main_class in z.namelist():
            major = z.read(main_class)[7]
            if major <= 52: print("8")
            elif major <= 55: print("11")
            elif major <= 61: print("17")
            elif major <= 65: print("21")
            else: print("25")
            sys.exit(0)
except: pass
print("unknown")
')
      fi

      if [ "$detected_java" == "25" ] || [[ "$version" == 26* ]] || [[ "$version" == 27* ]]; then
          JAVA_CMD="/usr/lib/jvm/java-25-openjdk-amd64/bin/java"
      elif [ "$detected_java" == "21" ]; then
          JAVA_CMD="/usr/lib/jvm/java-21-openjdk-amd64/bin/java"
      elif [ "$detected_java" == "17" ]; then
          JAVA_CMD="/usr/lib/jvm/java-17-openjdk-amd64/bin/java"
      elif [ "$detected_java" == "11" ]; then
          JAVA_CMD="/usr/lib/jvm/java-11-openjdk-amd64/bin/java"
      elif [ "$detected_java" == "8" ]; then
          JAVA_CMD="/usr/lib/jvm/java-8-openjdk-amd64/bin/java"
      else
          # Fallback to Pterodactyl Env Variable
          if [ "$JAVA_VERSION" == "21" ]; then 
              JAVA_CMD="/usr/lib/jvm/java-21-openjdk-amd64/bin/java"
          elif [ "$JAVA_VERSION" == "17" ]; then 
              JAVA_CMD="/usr/lib/jvm/java-17-openjdk-amd64/bin/java"
          elif [ "$JAVA_VERSION" == "11" ]; then 
              JAVA_CMD="/usr/lib/jvm/java-11-openjdk-amd64/bin/java"
          elif [ "$JAVA_VERSION" == "8" ]; then 
              JAVA_CMD="/usr/lib/jvm/java-8-openjdk-amd64/bin/java"
          else
              JAVA_CMD="/usr/lib/jvm/java-21-openjdk-amd64/bin/java"
          fi
      fi
      
      SIMD_ARG=""
      if [[ "$JAVA_CMD" == *java-21* ]] || [[ "$JAVA_CMD" == *java-25* ]] || [[ "$JAVA_CMD" == *java-17* ]]; then
          # SIMD vector API is fully supported on Java 17+ and heavily boosts PaperMC performance
          SIMD_ARG="--add-modules=jdk.incubator.vector"
      fi
      
      if { [[ "$JAVA_CMD" == *java-21* ]] || [[ "$JAVA_CMD" == *java-25* ]]; } && [ "$OPTIMIZE_SERVER" == "1" ]; then
          # EXTREME ZGC for Java 21/25 (Valorant Tier Zero-Lag Spikes)
          GC_FLAGS="-XX:+UseZGC -XX:+ZGenerational"
      fi

    echo -e "\e[32m[+] Starting Minecraft Server with $JAVA_CMD...\e[0m"
    exec $JAVA_CMD $MEM_ARG $SIMD_ARG $GC_FLAGS -jar server.jar nogui
}
