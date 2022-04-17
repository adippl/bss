ifeq ($(PREFIX),)
    PREFIX := /usr
endif

ifeq ($(DESTDIR),)
    DESTDIR := 
endif


make:
	echo nothing to compile


install:
	install -Dm 700 bss.sh $(DESTDIR)$(PREFIX)/bin/bss.sh
	install -Dm 700 btrfs_toolbox.sh $(DESTDIR)$(PREFIX)/bin/btrfs_toolbox.sh
	install -Dm 660 bsstab $(DESTDIR)/etc/bsstab
	install -d -m 0750 $(DESTDIR)/etc/cron.daily
	install -d -m 0750 $(DESTDIR)/etc/cron.weekly
	install -d -m 0750 $(DESTDIR)/etc/cron.monthly
	ln -s $(DESTDIR)$(PREFIX)/bin/btrfs_toolbox.sh $(DESTDIR)/etc/cron.daily/btrfs_device_stats.sh
	ln -s $(DESTDIR)$(PREFIX)/bin/btrfs_toolbox.sh $(DESTDIR)/etc/cron.weekly/btrfs_trim.sh
	ln -s $(DESTDIR)$(PREFIX)/bin/btrfs_toolbox.sh $(DESTDIR)/etc/cron.monthly/btrfs_scrub.sh
	
#local_install:
#	$(eval PREFIX := /usr/local)
#	install -Dm 700 bss.sh $(DESTDIR)$(PREFIX)/bin/bss.sh
#	install -Dm 660 bsstab $(DESTDIR)/etc/bsstab
#
#local_uninstall:
#	$(eval PREFIX := /usr/local)
#	rm $(DESTDIR)$(PREFIX)/bin/bss.sh
#	rm $(DESTDIR)/etc/bsstab

uninstall:
	rm $(DESTDIR)$(PREFIX)/bin/bss.sh
	rm $(DESTDIR)$(PREFIX)/bin/btrfs_toolbox.sh
	rm $(DESTDIR)/etc/bsstab
	unlink $(DESTDIR)/etc/cron.daily/btrfs_device_stats.sh
	unlink $(DESTDIR)/etc/cron.weekly/btrfs_trim.sh
	unlink $(DESTDIR)/etc/cron.monthly/btrfs_scrub.sh
