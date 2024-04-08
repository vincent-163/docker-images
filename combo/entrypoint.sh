#!/bin/bash

mkdir -p "${MYSQL_DATA_DIR}" "${REDIS_DATA_DIR}" "${SSH_DATA_DIR}" "${MONGODB_DATA_DIR}"

# Check if MySQL config exists in /data, if not copy the default one
if [ ! -f "${MYSQL_DATA_DIR}/mysqld.cnf" ]; then
    cp /etc/mysql/mysql.conf.d/mysqld.cnf ${MYSQL_DATA_DIR}/mysqld.cnf
fi

# Check if Redis config exists in /data, if not copy the default one
if [ ! -f "${REDIS_DATA_DIR}/redis.conf" ]; then
    cp /etc/redis/redis.conf ${REDIS_DATA_DIR}/redis.conf
fi

# Check if SSH config exists in /data, if not copy the default one
if [ ! -f "${SSH_DATA_DIR}/sshd_config" ]; then
	cp /etc/ssh/sshd_config "${SSH_DATA_DIR}/sshd_config"
fi
mkdir -p /run/sshd

# Check if MongoDB config exists in /data, if not copy the default one
if [ ! -f "${MONGODB_DATA_DIR}/mongod.conf" ]; then
    cp /etc/mongod.conf ${MONGODB_DATA_DIR}/mongod.conf
fi

# Start MySQL service to create user and database
service mysql start

# Create MySQL database and user
mysql -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '';"
mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
mysql -e "FLUSH PRIVILEGES;"

# Stop MySQL service
service mysql stop

# Generate SSH server keys if they do not exist
for key_type in rsa dsa ecdsa ed25519; do
    if [ ! -f "${SSH_DATA_DIR}/ssh_host_${key_type}_key" ]; then
        ssh-keygen -t ${key_type} -f "${SSH_DATA_DIR}/ssh_host_${key_type}_key" -N ''
        # Copy the generated keys to the appropriate location for SSHD to find them
        cp "${SSH_DATA_DIR}/ssh_host_${key_type}_key"* /etc/ssh/
    fi
done

# Generate user SSH keys if they do not exist
if [ ! -f "${SSH_DATA_DIR}/user_ssh_key" ]; then
    ssh-keygen -t rsa -f "${SSH_DATA_DIR}/user_ssh_key" -N ''
fi
# Prepare the authorized_keys file for the user
echo "command=\"echo 'This key can only be used for port forwarding.'\",no-agent-forwarding,no-X11-forwarding,no-pty $(cat ${SSH_DATA_DIR}/user_ssh_key.pub)" > /home/user/.ssh/authorized_keys

# Fix permissions
chown -R user:user /home/user/.ssh
chmod 600 /home/user/.ssh/authorized_keys

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

