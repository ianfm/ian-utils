# Provide targets "mkdir" and "clean" that work in both powershell and bash
# To test, run `make add` to create files and directories, then `make clean` to remove them.
COMMA := ,
SPACE := 
SPACE +=
FILES_TO_CLEAN = # Placeholder: redefine below at clean target

ifeq ($(OS),Windows_NT)
    # Windows specific commands
    PSQUIET = -ErrorAction SilentlyContinue
    MKDIR_CMD = mkdir # No -p option in Windows PowerShell -- it creates 'p' directory
    CLEAN_ME = $(subst $(SPACE) ,$(COMMA) ,$(FILES_TO_CLEAN))  # Powershell requires comma-separated list
    CLEAN_CMD = powershell -Command "& { param([string[]]$$files); Remove-Item $(PSQUIET) -Recurse $$files }" --
    ADD_FILES = powershell -Command "New-Item $(PSQUIET) -Path '.\a', '.\b', '.\c' -ItemType File; New-Item $(PSQUIET) -Path '.\obj' -ItemType Directory"
else
    # Linux specific commands
    CLEAN_CMD = rm -f
    MKDIR_CMD = mkdir -p
    CLEAN_ME = $(FILES_TO_CLEAN)  # bash requires space-separated list
    ADD_FILES = touch a b c obj/
endif

# debug: list commands used
all:
	@echo Usage:
	@echo   make add
	@echo   make clean
	@echo -------------
	@echo OS detected:         $(OS)
	@echo items to make/clean: $(CLEAN_ME)
	@echo command to make:     $(ADD_FILES)
	@echo command to clean:    $(CLEAN_CMD)
	@echo full clean command:  $(CLEAN_CMD) $(CLEAN_ME)

# For testing clean command
add:
	$(ADD_FILES)

# Redefine nearby for ease of use; $(CLEAN_ME) gets expanded here, not above
FILES_TO_CLEAN = a b c obj
clean:
	$(CLEAN_CMD) $(CLEAN_ME)

.phony: all add clean