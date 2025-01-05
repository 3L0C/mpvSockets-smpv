# Package info
NAME         := smpv
VERSION      := 0.0.1

# Install locations
PREFIX       := $$HOME/.local

# Project directories
SOURCE_DIR   := .
MPV_HOME     := $${MPV_HOME:-$$HOME/.config/mpv}
MPV_SCRIPTS  := $(MPV_HOME)/scripts
MPV_OPTS     := $(MPV_HOME)/script-opts

# Files
LUA_FILES    := $(wildcard $(SOURCE_DIR)/*.lua)
SHELL_FILES  := $(SOURCE_DIR)/$(NAME)/shell/$(NAME) $(SOURCE_DIR)/$(NAME)/shell/Test\ File.sh

# Targets
all: lua shell

lua: $(LUA_FILES)
	ln -fs -t "$(MPV_SCRIPTS)" "$$PWD/$^"

shell: $(SHELL_FILES)
	cp -f -t "$(DESTDIR)$(PREFIX)/bin" "$^"
	chmod 755 "$(DESTDIR)$(PREFIX)/bin/$(NAME)"
