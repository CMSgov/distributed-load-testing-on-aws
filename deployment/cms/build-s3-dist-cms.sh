#!/bin/bash
#
# This is a customized for CMS Cloud Service
#
# This assumes all of the OS-level configuration has been completed and git repo has already been cloned
#
# This script should be run from the repo's deployment directory
# cd deployment
# ./build-s3-dist-cms.sh -y
#
# Check to see if input has been provided:

if [ "$1" == "-y" ]; then
  echo "Proceed with building CMS customized installation artifacts for Distributed Load Testing on AWS."
else 
  echo "You are about build CMS customized installation artifacts for Distributed Load Testing on AWS."
  read -p "Are you sure you want to proceed? (type 'yes' to proceed) "
  if [[ ! $REPLY = "yes" ]]; then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
  fi
fi

set -e

# Get reference for all important folders
template_dir="$PWD"
build_dist_dir="$template_dir/cms-s3-assets"
source_dir="$template_dir/../../source"

echo "------------------------------------------------------------------------------"
echo "Rebuild distribution"
echo "------------------------------------------------------------------------------"
[ -e $build_dist_dir ] && rm -r $build_dist_dir
mkdir -p $build_dist_dir

echo "------------------------------------------------------------------------------"
echo "Creating custom-resource deployment package"
echo "------------------------------------------------------------------------------"
cd $source_dir/custom-resource/
rm -rf node_modules/
npm install --production
rm package-lock.json
zip -q -r9 $build_dist_dir/custom-resource.zip *

echo "------------------------------------------------------------------------------"
echo "Creating api-services deployment package"
echo "------------------------------------------------------------------------------"
cd $source_dir/api-services
rm -rf node_modules/
npm install --production
rm package-lock.json
zip -q -r9 $build_dist_dir/api-services.zip *

echo "------------------------------------------------------------------------------"
echo "Creating results-parser deployment package"
echo "------------------------------------------------------------------------------"
cd $source_dir/results-parser
rm -rf node_modules/
npm install --production
rm package-lock.json
zip -q -r9 $build_dist_dir/results-parser.zip *

echo "------------------------------------------------------------------------------"
echo "Creating task-canceler deployment package"
echo "------------------------------------------------------------------------------"
cd $source_dir/task-canceler
rm -rf node_modules/
npm install --production
rm package-lock.json
zip -q -r9 $build_dist_dir/task-canceler.zip *

echo "------------------------------------------------------------------------------"
echo "Creating task-runner deployment package"
echo "------------------------------------------------------------------------------"
cd $source_dir/task-runner
rm -rf node_modules/
npm install --production
rm package-lock.json
zip -q -r9 $build_dist_dir/task-runner.zip *

echo "------------------------------------------------------------------------------"
echo "Creating task-status-checker deployment package"
echo "------------------------------------------------------------------------------"
cd $source_dir/task-status-checker
rm -rf node_modules/
npm install --production
rm package-lock.json
zip -q -r9 $build_dist_dir/task-status-checker.zip *

echo "------------------------------------------------------------------------------"
echo "Creating ecr-checker deployment package"
echo "------------------------------------------------------------------------------"
cd $source_dir/ecr-checker
rm -rf node_modules/
npm install --production
rm package-lock.json
zip -q -r9 $build_dist_dir/ecr-checker.zip *

echo "------------------------------------------------------------------------------"
echo "Creating container deployment package"
echo "------------------------------------------------------------------------------"
cd $source_dir/container
# Downloading jetty 9.4.34.v20201102
curl -O https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-alpn-client/9.4.34.v20201102/jetty-alpn-client-9.4.34.v20201102.jar
curl -O https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-alpn-openjdk8-client/9.4.34.v20201102/jetty-alpn-openjdk8-client-9.4.34.v20201102.jar
curl -O https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-client/9.4.34.v20201102/jetty-client-9.4.34.v20201102.jar
curl -O https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-http/9.4.34.v20201102/jetty-http-9.4.34.v20201102.jar
curl -O https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-io/9.4.34.v20201102/jetty-io-9.4.34.v20201102.jar
curl -O https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-util/9.4.34.v20201102/jetty-util-9.4.34.v20201102.jar
zip -q -r9 $build_dist_dir/container.zip *
cp container-manifest.json $build_dist_dir/
rm -f *.jar

echo "------------------------------------------------------------------------------"
echo "Building console"
echo "------------------------------------------------------------------------------"
cd $source_dir/console
[ -e build ] && rm -r build
[ -e node_modules ] && rm -rf node_modules
npm install
npm run build
mkdir $build_dist_dir/console
cp -r ./build/* $build_dist_dir/console/

echo "------------------------------------------------------------------------------"
echo "Generate console manifest file"
echo "------------------------------------------------------------------------------"
cd $build_dist_dir
manifest=(`find console -type f | sed 's|^./||'`)
manifest_json=$(IFS=,;printf "%s" "${manifest[*]}")
echo "[\"$manifest_json\"]" | sed 's/,/","/g' > ./console-manifest.json

echo "------------------------------------------------------------------------------"
echo "Creating console deployment package"
echo "------------------------------------------------------------------------------"
cd $build_dist_dir
zip -q -r9 $build_dist_dir/console.zip console/*
rm -rf console

echo "------------------------------------------------------------------------------"
echo "Build S3 Packaging Complete"
echo "------------------------------------------------------------------------------"
