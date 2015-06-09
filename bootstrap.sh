#!/bin/bash

CONFIG_FILE_BOOTSTRAP="./.bootstrap_config";

CONFIG_FILE_VIRTUOSO="./config/virtuoso_config"

GIT_REPO_VIRTUOSO="https://github.com/Dockerizing/triplestore-virtuoso7.git";
GIT_REPO_VIRTUOSO_ONTOWIKI="https://github.com/Dockerizing/OntoWiki.git";
GIT_REPO_VIRTUOSO_BACKUP="https://github.com/Dockerizing/virtuoso-backup-docker.git";

GIT_REPO_VIRTUOSO_PATH="container/virtuoso-docker";
GIT_REPO_VIRTUOSO_ONTOWIKI_PATH="container/virtuoso-ontowiki-docker";
GIT_REPO_VIRTUOSO_BACKUP_PATH="container/virtuoso-backup-docker";

DOCKER_IMAGE_VIRTUOSO_TAG="virtuoso";
DOCKER_IMAGE_VIRTUOSO_ONTOWIKI_TAG="virtuoso-ontowiki";
DOCKER_IMAGE_VIRTUOSO_BACKUP_TAG="virtuoso-backup";

DOCKER_NAME_VIRTUOSO="virtuoso";

function bootstrap_virtuoso {
	
	rm -rf $GIT_REPO_VIRTUOSO_PATH;

	git clone $GIT_REPO_VIRTUOSO $GIT_REPO_VIRTUOSO_PATH;

	docker build --rm -t $DOCKER_IMAGE_VIRTUOSO_TAG ./$GIT_REPO_VIRTUOSO_PATH;

	source $CONFIG_FILE_BOOTSTRAP;
	BOOTSTRAPPED_VIRTUOSO="YES";
	set_config BOOTSTRAPPED_VIRTUOSO $BOOTSTRAPPED_VIRTUOSO;

	echo "Bootstrapping Virtuoso Completed!";
}

function bootstrap_virtuoso_ontowiki {

	rm -rf $GIT_REPO_VIRTUOSO_ONTOWIKI;

	git clone $GIT_REPO_VIRTUOSO_ONTOWIKI $GIT_REPO_VIRTUOSO_ONTOWIKI_PATH;

	docker build --rm -t $DOCKER_IMAGE_VIRTUOSO_ONTOWIKI_TAG ./$GIT_REPO_VIRTUOSO_ONTOWIKI_PATH;

	source $CONFIG_FILE_BOOTSTRAP;
	BOOTSTRAPPED_VIRTUOSO_ONTOWIKI="YES";
	set_config BOOTSTRAPPED_VIRTUOSO_ONTOWIKI $BOOTSTRAPPED_VIRTUOSO_ONTOWIKI;

	echo "Bootstrapping Virtuoso-OntoWiki Completed!";
}

function bootstrap_virtuoso_backup {

	rm -rf $GIT_REPO_VIRTUOSO_BACKUP_PATH;

	git clone $GIT_REPO_VIRTUOSO_BACKUP $GIT_REPO_VIRTUOSO_BACKUP_PATH;

	docker build --rm -t $DOCKER_IMAGE_VIRTUOSO_BACKUP_TAG ./$GIT_REPO_VIRTUOSO_BACKUP_PATH;

	source $CONFIG_FILE_BOOTSTRAP;
	BOOTSTRAPPED_VIRTUOSO_BACKUP="YES";
	set_config BOOTSTRAPPED_VIRTUOSO_BACKUP $BOOTSTRAPPED_VIRTUOSO_BACKUP;

	echo "Bootstrapping Virtuoso-Backup Completed!";
}

#Parameter: password
function run_virtuoso {
	
	source $CONFIG_FILE_BOOTSTRAP;

	if [ ! "$BOOTSTRAPPED_VIRTUOSO" == "YES" ]; then

		echo "Need To Bootstrap First!";
		return;
	fi

	if [ ! $# -eq 1 ]; then

		echo "Needs Password!";
		return;
	fi 

	source $CONFIG_FILE_VIRTUOSO;

	RUN_ID_VIRTUOSO=$(docker run -d --name=$DOCKER_NAME_VIRTUOSO -v $VIRTUOSO_DB:/var/lib/virtuoso/db -e PWDDBA="$1" -p $VIRTUOSO_PORT:8890 -p $VIRTUOSO_ODBC:1111 $DOCKER_IMAGE_VIRTUOSO_TAG);

	if [ ! $? -eq 0 ]; then

		echo "Docker Run: Virtuoso Error!";
		return;
	fi

	set_config RUN_ID_VIRTUOSO $RUN_ID_VIRTUOSO;
}

# Helper 
# Use this to set the new config value, needs 2 parameters. 
function set_config {
	sed -i "s/^\($1\s*=\s*\).*\$/\1$2/" $CONFIG_FILE_BOOTSTRAP
}

##############################################################################

if ! hash docker 2>/dev/null || ! hash git 2>/dev/null; then
	# or may docker needs sudo
	# then add user to docker group
	# sudo usermod -a -G docker 'username'
	# then restart system or
	# su - 'username'
	echo "Docker Or Git Not Installed!";
	return;
fi

if [ ! -f $CONFIG_FILE_BOOTSTRAP ]; then
	touch $CONFIG_FILE_BOOTSTRAP;
	echo "BOOTSTRAPPED_VIRTUOSO=NO" >> $CONFIG_FILE_BOOTSTRAP;
	echo "BOOTSTRAPPED_VIRTUOSO_ONTOWIKI=NO" >> $CONFIG_FILE_BOOTSTRAP;
	echo "BOOTSTRAPPED_VIRTUOSO_BACKUP=NO" >> $CONFIG_FILE_BOOTSTRAP;
	echo "RUN_ID_VIRTUOSO=NULL" >> $CONFIG_FILE_BOOTSTRAP;

	echo "Created Config File!";
fi

if [ "$1" == "virtuoso" ] || [ "$1" == "v" ]; then

	bootstrap_virtuoso;

	if [ "$2" == "ontowiki" ] || [ "$2" == "o" ] || [ "$3" == "ontowiki" ] || [ "$3" == "o" ]; then
		bootstrap_virtuoso_ontowiki;
	fi

	if [ "$2" == "backup" ] || [ "$2" == "b" ] || [ "$3" == "backup" ] || [ "$3" == "b" ]; then
		bootstrap_virtuoso_backup;
	fi

elif [ "$1" == "run" ] || [ "$1" == "r" ]; then

	if [ "$2" == "virtuoso" ] || [ "$2" == "v" ]; then

		#TODO: check if wants to start with onto and backup

		run_virtuoso "test";
	else

		echo "Unknown System!";
	fi
else
	echo "Not Supported Parameter!";
fi
