#!/bin/zsh

# Plays a Händel halleluja sound effect
function celebrate() {
    local sound_dir="$HOME/sound-effects"
    local sound_file="$sound_dir/Hallelujah-sound-effect.mp3"
    local zip_file="$HOME/Hallelujah-sound-effect.zip"

    mkdir -p "$sound_dir"

    if [ ! -f "$sound_file" ]; then
        echo "🎵 Sound file not found."

        read "REPLY?Do you want to download the Hallelujah sound effect? (y/n): "
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            echo "Downloading Hallelujah sound effect..."
            curl -L -o "$zip_file" "https://www.orangefreesounds.com/wp-content/uploads/Zip/Hallelujah-sound-effect.zip"
            
            unzip -o "$zip_file" -d "$sound_dir"
            rm "$zip_file"
            
            local downloaded_file=$(find "$sound_dir" -name "*Hallelujah*.mp3" | head -n 1)
            if [ -f "$downloaded_file" ]; then
                mv "$downloaded_file" "$sound_file"
            else
                echo "❌ Downloaded file not found. Aborting."
                return 1
            fi
        else
            echo "Sound file required to celebrate. Aborting."
            return 1
        fi
    fi

    afplay "$sound_file"
}
