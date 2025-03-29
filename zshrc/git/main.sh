#!/bin/zsh

function main(){
    git stash
    git checkout main
    git pull
    git stash pop
}
