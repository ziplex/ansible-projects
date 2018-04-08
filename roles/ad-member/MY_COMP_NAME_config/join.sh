#!/bin/bash

if [ "$(whoami)" != 'root' ]; then
        echo "У вас нет необходимых прав для ввода компьютера в домен."
		echo "Пожалуйста, запустите этот скрипт с правами администратора (sudo sh ./join.sh)"
        exit 1;
fi

apt update

apt install -y krb5-user samba samba-common-bin winbind ntp libpam-krb5 libpam-winbind libnss-winbind libpam-ccreds nscd nss-updatedb libnss-db

# Получаем директорию, в которой находится скрипт
ROOT_PATH=$(cd $(dirname $0) && pwd)

# Ставим правильного владельца и права
chown -R root:root $ROOT_PATH
chmod -R u=rw,g=r,o=r $ROOT_PATH

if ! [ -f /etc/resolvconf/resolv.conf.d/head.bak ] ; then
	cp /etc/resolvconf/resolv.conf.d/head /etc/resolvconf/resolv.conf.d/head.bak
fi

if ! [ -f /etc/hostname.bak ] ; then
	cp /etc/hostname /etc/hostname.bak
fi

if ! [ -f /etc/hosts.bak ] ; then
	cp /etc/hosts /etc/hosts.bak
fi

if ! [ -f /etc/ntp.conf.bak ] ; then
	cp /etc/ntp.conf /etc/ntp.conf.bak
fi

if ! [ -f /etc/krb5.conf.bak ] ; then
	cp /etc/krb5.conf /etc/krb5.conf.bak
fi

if ! [ -f /etc/samba/smb.conf.bak ] ; then
	cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
fi

if ! [ -f /etc/security/limits.conf.bak ] ; then
	cp /etc/security/limits.conf /etc/security/limits.conf.bak
fi

if ! [ -f /etc/nsswitch.conf.bak ] ; then
	cp /etc/nsswitch.conf /etc/nsswitch.conf.bak
fi

if ! [ -f /etc/pam.d/common-session.bak ] ; then
	cp /etc/pam.d/common-session /etc/pam.d/common-session.bak
fi

# cp -rf $ROOT_PATH/head /etc/resolvconf/resolv.conf.d/head
# cp -rf $ROOT_PATH/hostname /etc/hostname
# cp -rf $ROOT_PATH/hosts /etc/hosts
cp -rf $ROOT_PATH/ntp.conf /etc/ntp.conf
cp -rf $ROOT_PATH/krb5.conf /etc/krb5.conf
cp -rf $ROOT_PATH/smb.conf /etc/samba/smb.conf
cp -rf $ROOT_PATH/limits.conf /etc/security/limits.conf
cp -rf $ROOT_PATH/nsswitch.conf /etc/nsswitch.conf
cp -rf $ROOT_PATH/common-session /etc/pam.d/common-session

chmod u=rw,g=r,o=r /etc/resolvconf/resolv.conf.d/head
chmod u=rw,g=r,o=r /etc/hostname
chmod u=rw,g=r,o=r /etc/hosts
chmod u=rw,g=r,o=r /etc/ntp.conf
chmod u=rw,g=r,o=r /etc/krb5.conf
chmod u=rw,g=r,o=r /etc/samba/smb.conf
chmod u=rw,g=r,o=r /etc/security/limits.conf
chmod u=rw,g=r,o=r /etc/nsswitch.conf
chmod u=rw,g=r,o=r /etc/pam.d/common-session

/etc/init.d/networking restart
/etc/init.d/ntp restart
/etc/init.d/winbind stop
smbd restart
/etc/init.d/winbind start

echo ""
echo "**********"
echo "Сейчас будет произведена проверка, не втянут ли уже компьютер в какой-нибудь домен."
echo "Внимание! Если вылезет страшная ошибка, не пугайтесь. Все так, как должно быть."
echo "Просто продолжайте процедуру введения в домен."
echo "**********"
echo ""
echo "Если на этом этапе процесс завис и нет никакой реакции, просто нажмите Enter"
echo ""

if [ "$(net ads testjoin)" != "Join is OK" ]; then
	echo ""
	echo "**********"
	echo "Сейчас будет предложено авторизовать данный компьютер в домене. Пожалуйста, введите полное имя домена в верхнем регистре (DOMAIN.LOCAL), затем доменного пользователя с правами администратора, а затем его пароль."
	echo "**********"
	echo ""
	
	echo -n "Имя домена в верхнем регистре (DOMAIN.LOCAL): ";
	read DOMAINNAME
	
	echo -n "Имя доменного пользователя: ";
	read DOMAINUSER
	
	net ads join -U $DOMAINUSER -D $DOMAINNAME
fi

chmod -R u=rw,g=rw,o=rw $ROOT_PATH

if [ "$(lsb_release -si)" = "Ubuntu" ]; then
	if [ -f /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf ]; then
	    if ! [ -f /usr/share/lightdm/lightdm.conf.d/59-ubuntu.conf ]; then
			cp /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf /usr/share/lightdm/lightdm.conf.d/59-ubuntu.conf
			echo "greeter-show-manual-login=true" >> /usr/share/lightdm/lightdm.conf.d/59-ubuntu.conf
			echo "allow-guest=false" >> /usr/share/lightdm/lightdm.conf.d/59-ubuntu.conf
			echo "" >> /usr/share/lightdm/lightdm.conf.d/59-ubuntu.conf
			echo ""
			echo "**********"
			echo "Обнаружена система Ubuntu."
			echo ""
			echo "Отключен говстевой вход и активирована форма ручного ввода логина на экране приветствия."
			echo "Смотреть файл /usr/share/lightdm/lightdm.conf.d/59-ubuntu.conf"
			echo "**********"
			echo ""
	    fi
	fi
fi

echo ""

if [ "$(net ads testjoin)" = "Join is OK" ]; then
	echo "Компьютер успешно введен в домен!"
	echo "Резервные копии ваших оригинальных файлов имеют расширение *.bak и находятся в соответствующих папках."
	echo "Осталось только перезагрузить компьютер."
else
	echo "В процессе присоединения к домену возникли ошибки."
	echo "Смотрите подробнее листинг консоли."
fi

echo""