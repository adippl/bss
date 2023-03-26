ifeq ($(DESTDIR),)
 DESTDIR := 
 PREFIX := /usr/local
else
 ifeq ($(PREFIX),)
  PREFIX := /usr
 endif
endif

compile:
	echo nothing to compile

install:
	install -Dm 700 bss.sh $(DESTDIR)$(PREFIX)/bin/bss.sh
	install -Dm 700 btrfs_toolbox.sh $(DESTDIR)$(PREFIX)/bin/btrfs_toolbox.sh
	install -Dm 660 bsstab $(DESTDIR)/etc/bsstab
	install -d -m 0750 $(DESTDIR)/etc/cron.daily
	install -d -m 0750 $(DESTDIR)/etc/cron.weekly
	install -d -m 0750 $(DESTDIR)/etc/cron.monthly
	ln -s $(PREFIX)/bin/btrfs_toolbox.sh $(DESTDIR)/etc/cron.daily/btrfs_device_stats.sh
	ln -s $(PREFIX)/bin/btrfs_toolbox.sh $(DESTDIR)/etc/cron.weekly/btrfs_trim.sh
	ln -s $(PREFIX)/bin/btrfs_toolbox.sh $(DESTDIR)/etc/cron.monthly/btrfs_scrub.sh
	
uninstall:
	rm $(DESTDIR)$(PREFIX)/bin/bss.sh
	rm $(DESTDIR)$(PREFIX)/bin/btrfs_toolbox.sh
	rm $(DESTDIR)/etc/bsstab
	unlink $(DESTDIR)/etc/cron.daily/btrfs_device_stats.sh
	unlink $(DESTDIR)/etc/cron.weekly/btrfs_trim.sh
	unlink $(DESTDIR)/etc/cron.monthly/btrfs_scrub.sh
