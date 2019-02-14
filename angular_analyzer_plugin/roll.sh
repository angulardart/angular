# File to aid in rolling angular_analyzer_plugin into the angular repo. Assumes
# you have a copy of the angular repo on your machine from which you want to
# sync.
#
# Usage: ./roll.sh path_to_plugin_repo
SOURCE=$1
cp $SOURCE/*.md .
cp $SOURCE/angular_analyzer_plugin/pubspec.yaml .
