ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif

install:
	echo installing to: $(PREFIX)
	echo cp bss.sh $(PREFIX)/bin/bss.sh
	cp bss.sh $(PREFIX)/bin/bss.sh
	echo chmod +x $(PREFIX)/bin/bss.sh

	echo cp bss.conf /etc/bss.conf
	cp bss.conf /etc/bss.conf

uinstall:
	echo rm $(PREFIX)/bin/bss.sh
	rm $(PREFIX)/bin/bss.sh
	echo rm /etc/bss.conf
	echo rm /etc/bss.conf
