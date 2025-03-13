#!/bin/bash

# Plays a Händel halleluja sound effect

alias celebrate='if [ ! -f ~/Hallelujah-sound-effect/Hallelujah-sound-effect.mp3 ]; then wget -O ~/Hallelujah-sound-effect.zip https://www.orangefreesounds.com/wp-content/uploads/Zip/Hallelujah-sound-effect.zip && unzip -o ~/Hallelujah-sound-effect.zip -d ~/Hallelujah-sound-effect && rm ~/Hallelujah-sound-effect.zip && (command -v mpg123 >/dev/null 2>&1 || sudo apt-get install -y mpg123); fi && mpg123 ~/Hallelujah-sound-effect/Hallelujah-sound-effect.mp3'