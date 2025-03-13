#!/bin/bash

# Plays a Händel halleluja sound effect
function celebrate() {
    local sound_dir="$HOME/Hallelujah-sound-effect"
    local sound_file="$sound_dir/Hallelujah-sound-effect.mp3"
    local zip_file="$HOME/Hallelujah-sound-effect.zip"

    if [ ! -f "$sound_file" ]; then
        wget -O "$zip_file" "https://www.orangefreesounds.com/wp-content/uploads/Zip/Hallelujah-sound-effect.zip"
        unzip -o "$zip_file" -d "$sound_dir"
        rm "$zip_file"
        
        if ! command -v mpg123 >/dev/null 2>&1; then
            sudo apt-get install -y mpg123
        fi
    fi

    mpg123 "$sound_file"
}