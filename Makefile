.PHONY: lpass_login
ifeq ($(findstring Not,$(shell lpass status)),Not)
    RESULT=FALSE
else
    RESULT=TRUE
endif

lpass_login:
ifeq ($(RESULT),FALSE)
ifeq ($(strip $(user)),)
	read -p "Enter user:" user; \
	lpass login $$user;
else
	lpass login $$user;
endif
endif
