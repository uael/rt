# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: alucas- <alucas-@student.42.fr>            +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 1970/01/01 00:00:42 by alucas-           #+#    #+#              #
#    Updated: 1970/01/01 00:00:42 by alucas-          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

PROJECT ?= rt
WFLAGS = -Werror -Wextra -Wall
RCFLAGS = $(WFLAGS) -O2 -DNDEBUG
DCFLAGS = $(WFLAGS) -g3
SCFLAGS = -fsanitize=address,undefined -ferror-limit=5 $(DCFLAGS)
CC ?= gcc
UNAME_S := $(shell uname -s)

INC_PATH = include
SRC_PATH = src
OBJ_DIR ?= obj
OBJ_PATH ?= $(OBJ_DIR)/rel
3TH_PATH = .

LIBS = ft
ifneq (,$(findstring dev,$(PROJECT)))
LIB_NAME = $(addsuffix .dev, $(LIBS))
else ifneq (,$(findstring san,$(PROJECT)))
LIB_NAME = $(addsuffix .san, $(LIBS))
else
LIB_NAME = $(LIBS) glfw m dl
endif
3TH_NAME = libft
SRC_NAME = \
	glad.c main.c

3TH = $(addprefix $(3TH_PATH)/, $(3TH_NAME))
OBJ = $(addprefix $(OBJ_PATH)/, $(SRC_NAME:.c=.o))
LNK = $(addprefix -L, $(3TH) $(HOME)/.brew/lib/)
INC = $(addprefix -I, $(INC_PATH) $(addsuffix /include, $(3TH)) $(HOME)/.brew/include/)
LIB = $(addprefix -l, $(LIB_NAME))
DEP = $(OBJ:%.o=%.d)

ifeq ($(UNAME_S),Darwin)
  LIB += -framework OpenGl
endif

PRINTF=test $(VERBOSE)$(TRAVIS) || printf

ifneq (,$(findstring dev,$(PROJECT)))
3DE = $(shell echo "$(3TH_NAME)" | sed -E "s|([\.a-zA-Z]+)|$(3TH_PATH)/\1/\1.dev.a|g")
else ifneq (,$(findstring san,$(PROJECT)))
3DE = $(shell echo "$(3TH_NAME)" | sed -E "s|([\.a-zA-Z]+)|$(3TH_PATH)/\1/\1.san.a|g")
else
3DE = $(shell echo "$(3TH_NAME)" | sed -E "s|([\.a-zA-Z]+)|$(3TH_PATH)/\1/\1.a|g")
endif

all:
ifneq ($(3TH_NAME),)
	$(foreach 3th,$(3TH_NAME),$(MAKE) -C $(3TH_PATH)/$(3th) &&) true
endif
	@$(PRINTF) "%-20s" "$(PROJECT): exe"
	$(MAKE) $(PROJECT) "CFLAGS = $(RCFLAGS)" "OBJ_PATH = $(OBJ_DIR)/rel"
	@$(PRINTF) "\r\033[20C\033[0K\033[32mOK\033[0m\n"

dev:
ifneq ($(3TH_NAME),)
	$(foreach 3th,$(3TH_NAME),$(MAKE) -C $(3TH_PATH)/$(3th) dev &&) true
endif
	$(MAKE) $(PROJECT).dev "PROJECT = $(PROJECT).dev" "CFLAGS = $(DCFLAGS)" \
	  "OBJ_PATH = $(OBJ_DIR)/dev"
	@$(PRINTF) "\r\033[20C\033[0K\033[32mOK\033[0m\n"

san:
ifneq ($(3TH_NAME),)
	+$(foreach 3th,$(3TH_NAME),$(MAKE) -C $(3TH_PATH)/$(3th) san &&) true
endif
	@$(PRINTF) "%-20s" "$(PROJECT).san: exe"
	$(MAKE) $(PROJECT).san "PROJECT = $(PROJECT).san" "CFLAGS = $(SCFLAGS)" \
	  "OBJ_PATH = $(OBJ_DIR)/san" "CC = clang"
	@$(PRINTF) "\r\033[20C\033[0K\033[32mOK\033[0m\n"

$(PROJECT): $(3DE) $(OBJ)
	@$(PRINTF) "\r\033[20C\033[0K$@"
	$(CC) $(CFLAGS) $(INC) $(LNK) $(OBJ) $(LIB) -o $(PROJECT)

$(SRC_PATH)/glad.c:
	@$(PRINTF) "\r\033[20C\033[0K$@"
	@python -m glad --out-path . --generator c --spec gl --omit-khrplatform 2>/dev/null 1>/dev/null

$(OBJ_PATH)/%.o: $(SRC_PATH)/%.c | $(OBJ_PATH)
	@$(PRINTF) "\r\033[20C\033[0K$<"
	$(CC) $(CFLAGS) $(INC) -MMD -MP -c $< -o $@

$(OBJ_PATH):
	mkdir -p $(dir $(OBJ))

clean:
	rm -rf $(OBJ_DIR) include/glad src/glad.c
	@$(PRINTF) "%-20s\033[32mOK\033[0m\n" "$(PROJECT): $@"

fclean: clean
ifneq ($(3TH_NAME),)
	+$(foreach 3th,$(3TH_NAME),$(MAKE) -C $(3TH_PATH)/$(3th) fclean &&) true
endif
	rm -f $(PROJECT){,.san,.dev}
	@$(PRINTF) "%-20s\033[32mOK\033[0m\n" "$(PROJECT): $@"

re: clean all

-include $(DEP)

ifndef VERBOSE
 ifndef TRAVIS
.SILENT:
 endif
endif

.PHONY: all, dev, san, mecry, $(PROJECT), clean, fclean, re
