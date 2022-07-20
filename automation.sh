name=sruthi
s3Bucket=upgrad-sruthi

# Update of the package details and the package list

sudo apt update -y

# Install the apache2 package if it is not already installed

dpkg -s apache2 &> /dev/null

if [ $? -ne 0 ]
  then
    echo "Installing Apache2"
    sudo apt-get install apache2

else
    echo "Apache2 already installed"
    fi
# Ensure that the apache2 service is running

apacheStatus=$(service apache2 status | grep -i Active | awk '{print $2}')
if [ "$apacheStatus" = "inactive" ]
then
        systemctl start apache2
        echo "Started Apache2 service"
fi

# Ensure that the apache2 service is enabled

apache2Status=$(service --status-all | grep apache2 | awk '{print $2}')
if [ "$apacheStatus" = "+" ]
then
        echo "Apache service is already enabled"
else
        service apache2 start
        echo "Enabled Apache2 service"
fi

# Create a tar archive of apache2 access logs and error logs

timestamp=$(date '+%d%m%Y-%H%M%S')
cd /var/log/apache2
sudo tar -czvf /var/tmp/$name-httpd-logs-$timestamp.tar access.log error.log

# Copy the archive to the s3 bucket

aws s3 cp /var/tmp/$name-httpd-logs-$timestamp.tar s3://${s3Bucket}/$name-httpd-logs-$timestamp.tar

# Check for the presence of the inventory.html file

if [[ ! -f /var/www/html/inventory.html ]]; then
    echo "Creating Inventory file"
    sudo touch /var/www/html/inventory.html
    sudo chmod 777 /var/www/html/inventory.html
    sudo echo "Log Type&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Time Created&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Type&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Size<br>" >> /var/www/html/inventory.html
fi

sudo echo "httpd-logs&nbsp;&nbsp;&nbsp;&nbsp;$timestamp&nbsp;&nbsp;&nbsp;&nbsp;tar&nbsp;&nbsp;&nbsp;&nbsp;$filesize Bytes<br>" >> /var/www/html/inventory.html


# Cron Job

if [ -f /etc/cron.d/automation ]
then
        echo "Cron job is scheduled already"
else
        touch /etc/cron.d/automation
        echo "0 0 * * * root /root/Automation_Project/automation.sh" >> /etc/cron.d/automation
        echo "Cron Job is scheduled at 12:00 everyday"
fi

