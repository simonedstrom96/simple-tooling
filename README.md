# Simple tooling

A collection of simple tools you can use as a developer to boost your productivity

## Prerequisites

- Python so that it is calleable via ```python3``` in the terminal
- jq: install via ```sudo apt install jq```

## Installation

- Clone this repo and `cd` into it
- Run `cp .env.example .env` to copy the .env file
- Enter your OpenAI API key or other LLM provider variables into the .env file. The LLM provider used depends on what env variables you provide.
- Add this line to your ~/.bashrc: `source <SIMPLE_TOOLING_REPO_PATH>/bashrc/index.sh` where `<SIMPLE_TOOLING_REPO_PATH>` is the path to this repository

## Usage

### Shell commands

- `doit`: Run `doit` followed by an input prompt to get a shell command that does the specified action. Eg. `doit list all files` should result in your next terminal input being filled with `ls -a`.
- `wat`: Run `wat` followed by an input to get a quick LLM explanation of your query. Eg. `wat what is 1+1` should result in `1+1 equals 2` being echoed to your terminal.
- `celebrate`: Plays a Handel Hallelujah sound effect (if using WSL only works with Windows 11)
