CFLAGS		:= -Wall

SRC_FILES_SH	:= $(wildcard *.sh)
SRC_FILES_C	:= $(wildcard *.c)
LIB_FILES_SH	:= shell-lib.sh
BIN_FILES	:= $(filter-out $(LIB_FILES_SH:.sh=), $(SRC_FILES_SH:.sh=)) \
	           $(filter-out $(LIB_FILES_C:.c=),   $(SRC_FILES_C:.c=))
LIB_FILES	:= $(LIB_FILES_SH)
TOOLS_ZIP	:= tools.zip
TOOLS_TAR	:= tools.tar

.INTERMEDIATE	: $(BIN_FILES)

.PHONY		: install
install		:: $(BIN_FILES); install -m 755 $? $(HOME)/bin
install		:: $(LIB_FILES); install -m 644 $? $(HOME)/bin

.PHONY		: dist
dist:		$(BIN_FILES) $(LIB_FILES)
		  cd $(HOME); make push-bin

$(TOOLS_ZIP)	: $(BIN_FILES) $(LIB_FILES); zip -u $@ $?
$(TOOLS_TAR)	: $(BIN_FILES) $(LIB_FILES); tar cf $@ $?

.PHONY		: clean
clean		:

.PHONY		: realclean
realclean	: clean
		  $(RM) $(TOOLS_ZIP) $(TOOLS_TAR)

.PHONY		: what
what		:
		  $(info SRC_FILES_SH = $(SRC_FILES_SH))
		  $(info SRC_FILES_C  = $(SRC_FILES_C) )
		  $(info LIB_FILES_SH = $(LIB_FILES_SH))
		  $(info BIN_FILES    = $(BIN_FILES)   )
		  $(info LIB_FILES    = $(LIB_FILES)   )
		@ true
