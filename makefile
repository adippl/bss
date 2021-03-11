ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif

install:
	cp bss.sh $(PREFIX)/bin/bss.sh
	chmod +x $(PREFIX)/bin/bss.sh
	cp bss.conf /etc/bss.conf

uinstall:
	rm $(PREFIX)/bin/bss.sh
	rm /etc/bss.conf
