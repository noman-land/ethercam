# Ethercam

Hackathon project for EthBoston (2019): https://devpost.com/software/ethercam

## Development
1. ssh into the Raspberry pi and install nvm and the latest nodejs. Make note of the node version.

2. Clone the project *as a bare repo*.

    By default it's assumed your git project folder is `~/git/ethercam.git`

    `git clone --bare git://theproject.git`

3. Create a folder for the actual built project to live

    By default it's assumed your built project folder is `~/projects/ethercam`

4. Add the `hooks/post-receive` file from this project to `~/git/ethercam.git/hooks/`

    This will make it so that pushing to this repo will automatically check it out in the `projects` folder and build it.

5. Add the `systemd/nodeserver.service` file from this project to `/etc/systemd/system/`, making sure to change the node version number and location in the `ExecStart` section if needed

    This starts up the node project as soon as the pi boots

6. Make the file executable with `sudo chmod +x /etc/systemd/system/nodeserver.service`

7. Enable the systemd service with `sudo systemctl enable nodeserver`
