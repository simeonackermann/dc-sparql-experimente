#!/bin/bash

#
# This script runs a Docker Compose environment a given number of times
# run: ./test.sh [number]
#
# @author: Simeon Ackermann (amseon@web.de)
#

# Init the vars
########################

# the result folder
RESULT_DIR=$PWD/Results

# how much runs we will do
RUN_TIMES=1

# the prefix for the container names
COMPOSE_PREFIX="sp-ts-"

# title of this project
TITLE="SPARQL Experiments"

# End of init
########################


function help()
{
	echo "Please use: (e.g. ./test.sh [numbers of testcases])"
}

function main()
{
	echo "_____________________________________________"
	echo -e "\n# ${TITLE} Setup #\n"

	if [[ "$1" = "help"  ]]; then
		help
		exit 0
	fi

	if [[ -n $1 ]]; then
		RUN_TIMES=$1
	fi
	echo -e "# Number of tests: ${RUN_TIMES} \n"

	exit 0

	# Do some startup checks
	check

	#for RUN in {1..$RUN_TIMES}
	for (( run=1; run<=$RUN_TIMES; run++ )); do
		run $run
	done
}

function run()
{
	run=$1

	echo -e "# ${TITLE} - Start run ${run}"
	echo -e "_____________________________________________\n"	

	# first may cleanup old containers
	cleanup

	# start env
	docker-compose up

	# cleanup again after run
	cleanup

	# move results
	mkdir -p ${RESULT_DIR}/Test-${run}
	cp ${RESULT_DIR}/results_0/org.aksw.iguana.testcases.StressTestcase1.0/1/0/*.csv ${RESULT_DIR}/Test-${run}/
	rm -rf ${RESULT_DIR}/results_0
	mv ${RESULT_DIR}/results_0.zip ${RESULT_DIR}/Test-${run}.zip

	# Done ;)
	echo "_____________________________________________"
	echo -e "\n# ${TITLE} - Run ${run} done"
	echo -e "\n# Check your results in ${RESULT_DIR}/Test-${run}\n"
}

function cleanup()
{
	# may stop containers
	if [[ ! -z $(docker ps -a -q --filter "name=${COMPOSE_PREFIX}") ]]; then
		echo "[INFO] Stop our running containers ..."
		docker stop $(docker ps -a -q --filter "name=${COMPOSE_PREFIX}")
	fi
	
	# delete container
	if [[ ! -z $(docker ps -a -q --filter "name=${COMPOSE_PREFIX}") ]]; then
		echo "[INFO] Delete the containers to cleanup ..."
		docker rm -v $(docker ps -a -q --filter "name=${COMPOSE_PREFIX}")
	fi
}

function check()
{
	command -v docker >/dev/null 2>&1 || { 
		echo >&2 "[ERROR] Please install Docker (http://docker.com/) first!"
		exit 1
	}
	command -v docker-compose >/dev/null 2>&1 || { 
		echo >&2 "[ERROR] Please install Docker Compose (http://docs.docker.com/compose/) first!"
		exit 1
	}

	# cleanup results dir
	# rm -rf ${RESULT_DIR}/*
}

main $1