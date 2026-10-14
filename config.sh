#!/bin/bash
#1) Cambiar a root
#Ingresar al Shell interactivo como root (entorno completo)
sudo -i

#2) Configuración de las interfaces de red
#Configurar Interfaz LAN para conectarse por SSH
#Interfaz LAN
nmcli con mod ens160 ipv4.addresses 10.10.10.1/24
nmcli con mod ens160 ipv4.method manual
nmcli con up ens160
#Verificar el nombre de la conexión de las interfaces
nmcli device status

#Cambiamos el id de la conexión de la interfaz VPN
nmcli con mod "Conexión cableada 1" connection.id ens224

#Interfaz VPN
nmcli con mod ens224 ipv4.addresses 172.16.10.2/24
nmcli con mod ens224 ipv4.gateway 172.16.10.1
nmcli con mod ens224 ipv4.dns "8.8.8.8 8.8.4.4"
nmcli con mod ens224 ipv4.method manual
nmcli con up ens224

#3) Pruebas de conexión
#Prueba de Conexión con Cliente 1
ping -c 3 10.10.10.5

#Prueba de Conexión con Cliente 2
ping -c 3 10.10.10.6

#Prueba de Conexión con Virtual Network Gateway
ping -c 3 172.16.10.1

#Prueba de Conexión con Servidor Web
ping -c 3 192.168.1.5

#4) Habilitar IP Forwarding
# Activarlo permanentemente
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

sysctl net.ipv4.ip_forward
# Debe mostrar: net.ipv4.ip_forward = 1

#5) Instalar IPTables
# Instalar iptables
dnf install iptables iptables-services -y

# Detener y deshabilitar firewalld para evitar conflictos
systemctl stop firewalld
systemctl disable firewalld

# Habilitar iptables
systemctl enable iptables
systemctl start iptables

#6) Configurar NAT con IPTables
# Enmascarar ip origen del tráfico hacia el servidor web
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -d 192.168.1.5 -p tcp --dport 80 -o ens224 -j SNAT --to-source 172.16.10.2

# Permitir tráfico de LAN hacia WAN (Optional)
#iptables -t nat -A POSTROUTING -o ens224 -j MASQUERADE

# Permitir reenvío de paquetes entre interfaces
iptables -I FORWARD -i ens160 -o ens224 -j ACCEPT
iptables -I FORWARD -i ens224 -o ens160 -m state --state RELATED,ESTABLISHED -j ACCEPT

#7) Guardar las reglas permanentemente
# Guardar reglas actuales
service iptables save

# Verificar que se guardaron en
cat /etc/sysconfig/iptables

#8) Verificar las reglas activas
# Ver todas las reglas
iptables -L -v -n

# Ver reglas de NAT específicamente
iptables -t nat -L -v -n
