ifeq ($(PREFIX),)
    PREFIX := /usr
endif

ifeq ($(DESTDIR),)
    DESTDIR := 
endif




install:
	install -Dm 700 bss.sh $(DESTDIR)$(PREFIX)/bin/bss.sh
	install -Dm 660 bsstab $(DESTDIR)/etc/bsstab

local_install:
	$(eval PREFIX := /usr/local)
	install -Dm 700 bss.sh $(DESTDIR)$(PREFIX)/bin/bss.sh
	install -Dm 660 bsstab $(DESTDIR)/etc/bsstab

local_uninstall:
	$(eval PREFIX := /usr/local)
	rm $(DESTDIR)$(PREFIX)/bin/bss.sh
	rm $(DESTDIR)/etc/bsstab

uninstall:
	rm $(DESTDIR)$(PREFIX)/bin/bss.sh
	rm $(DESTDIR)/etc/bsstab
