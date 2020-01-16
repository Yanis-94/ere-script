#!/bin/bash
#
#
##Valeur entrées pour la configuration du script
#passwd		-Mot de passe du user
#$usr 		-User utilisé pour le site
#$dir		-répertoire des fichiers web 
#$servn		-adresse du serveur sans le www
#$cname		-alias 
datenum=$(date +%Y%m%d)
#Example
#Web directory = /var/www/
#ServerName    = ere71.lan
#
#
#

read -p "Entrez le nom du serveur sans le www : " servn
read -p "Entrez le chemin absolu  du répertoire web : " dir
read -p "Entrez  l'utilisateur que vous voulez utiliser : " usr
read -p "Entrez le mot de passe de l'utilisateur : " passwd
if ! mkdir -p $dir$servn/{htdocs,logs}; then 
echo "Le répertoire existe déjà !" 
else
echo "Le répertoire a été crée avec succès !" 
fi
useradd $usr -d $dir$servn/htdocs -s /bin/false
echo "$usr:$passwd" | chpasswd
#usermod -a -G ftp $usr
echo "Uttilisateur crée avec succès !"
chown -R $usr:www-data $dir$servn
chmod -R '775' $dir$servn

#Creation de la database
mysql -u root -e "CREATE  USER '$usr'@'%' IDENTIFIED BY '$passwd';"
mysql -u root -e "CREATE DATABASE $usr;"
mysql -u root -e "GRANT ALL PRIVILEGES ON $usr.* TO '$usr'@'%';"
mysql -u root -e "FLUSH PRIVILEGES;"
echo "La database a été crée avec succès !"

#Configuration du ftp pour le user
echo "<Directory $dir$servn/htdocs>
Umask 022
AllowOverwrite off
<Limit LOGIN>
AllowUser $usr
DenyAll
</Limit>
<Limit All>
AllowUser $usr
DenyAll
</Limit>
</Directory>" >> /etc/proftpd/proftpd.conf


#Creation du Vhost
echo "#$servn
<VirtualHost *:80>
ServerName $servn
DocumentRoot $dir$servn/htdocs
ErrorLog $dir$servn/logs/error.log
</VirtualHost>" > /etc/apache2/sites-available/$servn.conf
if ! echo -e /etc/apache2/sites-available/$servn.conf; then 
echo "Virtual host wasn't created !" 
else
echo "Virtual host created !"
fi
a2ensite $servn.conf
echo "Voulez-vous redémarrer le serveur apache ?"
read q
if [[ "${q}" == "yes" ]] || [[ "${q}" == "y" ]]; then
service apache2 restart
fi 
#Enregistrement DNS
echo $servn. IN A 192.168.1.2 >> /etc/bind/db.ere71.lan
rndc reload
#awk 'BEGIN{ser=strftime("%Y%m%d",systime() )*100} /serial/{sub($1,$1 < ser ? ser : $1+1)}1' /etc/bind/db.ere71.lan
#perl -pe 's/(20[0-9]{3,})/$1+1/e' /etc/bind/db.ere71.lan
#sed -i -r    "s/.*[0-9]\{0,\}.*; Serial/	"$datenum"01 ; Serial/" /etc/bind/db.ere71.lan
echo "Tout s'est déroulé correctement ! " 
