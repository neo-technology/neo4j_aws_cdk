# install necessary packages
sudo yum -y install java-17-amazon-corretto-headless

# install neo4j db
sudo rpm --import https://debian.neo4j.com/neotechnology.gpg.key
sudo cat <<EOF >/etc/yum.repos.d/neo4j.repo
[neo4j]
name=Neo4j RPM Repository
baseurl=https://yum.neo4j.com/stable/5
enabled=1
gpgcheck=1
EOF
sudo NEO4J_ACCEPT_LICENSE_AGREEMENT=yes yum -y install neo4j-enterprise-5.3.0
sudo neo4j-admin dbms set-initial-password THIS_IS_A_SUPER_SECRET_SECRET 

# prepare and mount the db partition
sudo parted -s /dev/sdm mklabel gpt
sudo parted -s -a optimal /dev/sdm mkpart primary 0% 100% 
sudo mkfs.xfs /dev/sdm1
sudo mkdir /neo4j
sudo  echo '/dev/sdm1  /neo4j       auto    defaults  0  1' | sudo tee -a /etc/fstab >/dev/null
sudo mount -a
sudo chown -R neo4j.neo4j /neo4j 

# download and install necessary extensions
sudo curl --location --output /neo4j/plugins/neosemantics-5.1.0.0.jar https://github.com/neo4j-labs/neosemantics/releases/download/5.1.0.0/neosemantics-5.1.0.0.jar
sudo cp /var/lib/neo4j/labs/apoc-5.3.0-core.jar /neo4j/plugins/
sudo curl --location --output /tmp/neo4j-graph-data-science-2.2.6.zip https://graphdatascience.ninja/neo4j-graph-data-science-2.2.6.zip
sudo unzip /tmp/neo4j-graph-data-science-2.2.6.zip -d /neo4j/plugins/
sudo rm /tmp/neo4j-graph-data-science-2.2.6.zip 
sudo  echo 'dbms.security.procedures.unrestricted=gds.*,apoc.*,n10s.*' | sudo -u neo4j tee -a /etc/neo4j/neo4j.conf >/dev/null
sudo  echo 'dbms.security.procedures.allowlist=apoc.*,gds.*,n10s.*' | sudo -u neo4j tee -a /etc/neo4j/neo4j.conf >/dev/null
sudo  echo 'server.unmanaged_extension_classes=n10s.endpoint=/rdf' | sudo -u neo4j tee -a /etc/neo4j/neo4j.conf >/dev/null
sudo  echo 'server.http.listen_address=0.0.0.0:7474' | sudo -u neo4j tee -a /etc/neo4j/neo4j.conf >/dev/null
sudo  echo 'server.bolt.listen_address=0.0.0.0:7687' | sudo -u neo4j tee -a /etc/neo4j/neo4j.conf >/dev/null

# enable and start service
sudo systemctl enable neo4j 
sudo systemctl daemon-reload

# TODO: certificates and db configuration
sudo amazon-linux-extras install -y epel
sudo yum install -y certbot


# key       /etc/letsencrypt/live/dev-kg-who-ewaa.graphapp.io/privkey.pem
# fullchain /etc/letsencrypt/live/dev-kg-who-ewaa.graphapp.io/fullchain.pem
# chain     /etc/letsencrypt/live/dev-kg-who-ewaa.graphapp.io/chain.pem
# cert      /etc/letsencrypt/live/dev-kg-who-ewaa.graphapp.io/cert.pem

sudo parted -s /dev/sdm mklabel gpt
sudo parted -s -a optimal /dev/sdm mkpart primary 0% 100% 
sudo mkfs.xfs /dev/sdm1
sudo mkdir /neo4j
sudo  echo '/dev/sdm1  /neo4j       auto    defaults  0  1' | sudo tee -a /etc/fstab >/dev/null
sudo mount -a
sudo chown -R neo4j.neo4j /neo4j 

# after DNS changes (manual)
sudo certbot certonly -d <FQDN> --standalone -m <ADMIN_EMAIL> --agree-tos -n

sudo chmod a+rx /etc/letsencrypt/archive/
sudo chmod a+rx /etc/letsencrypt/archive/<FQDN>/
sudo chmod a+r /etc/letsencrypt/archive/<FQDN>/*

sudo chmod a+rx /etc/letsencrypt/live/
sudo chmod a+rx /etc/letsencrypt/live/<FQDN>/
sudo chmod a+r /etc/letsencrypt/live/<FQDN>/*

# sudo systemctl start neo4j
