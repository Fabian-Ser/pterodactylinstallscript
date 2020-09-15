sudo useradd --no-create-home --shell /bin/false node_exporter
cd /root
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
tar xvf node_exporter-1.0.1.linux-amd64.tar.gz
sudo cp node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
rm -rf node_exporter-1.0.1.linux-amd64.tar.gz node_exporter-1.0.1.linux-amd64
sudo cd /etc/systemd/system/
wget https://raw.githubusercontent.com/Fabian-Ser/pterodactylinstallscript/master/node_exporter.service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
cd /
sudo systemctl status node_exporter
