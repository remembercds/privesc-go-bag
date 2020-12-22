cp libsnoopy.so /usr/local/lib/libsnoopy.so
echo '/usr/local/lib/libsnoopy.so' >> /etc/ld.so.preload
echo '[snoopy]' > /etc/snoopy.ini
service apache2 restart
service smbd restart
