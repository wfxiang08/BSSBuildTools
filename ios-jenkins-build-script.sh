# Defining the environment variables we're going to use
DISTRIBUTION_IDENTITY="iPhone Distribution: John Doe"
PROVISIONING_PROFILE_PATH="<path to your mobileprovision file>"
OSVERSION="5.1"
# pwd points to Jenkin's workspace directory for this build job - We're going to use a separate subfolder within the workspace identified by the build number (which we automatically get from Jenkins)
BUILD_DIRECTORY="$(pwd)/build-${BUILD_NUMBER}"
PLIST_PATH="$(pwd)/BSSCISample/BSSCISample-Info.plist"

# Determine if we have any changes in our git workspace

# Determine the UUID of the provisioning profile and copy it to the appropriate location so Xcode can find it
PROFILE_UUID=$(grep "<key>UUID</key>" "$PROVISIONING_PROFILE_PATH" -A 1 --binary-files=text | sed -E -e "/<key>/ d" -e "s/(^.*<string>)//" -e "s/(<.*)//")
cp "$PROVISIONING_PROFILE_PATH" ~/Library/MobileDevice/Provisioning\ Profiles/$PROFILE_UUID.mobileprovision


# Use this line if you want to build a workspace
# XCODE_BUILD_COMMAND="xcodebuild -sdk iphoneos${OS_VERSION} -workspace BSSCISample.xcworkspace -scheme \"BSSCISample-Ad-Hoc\" -configuration \"Ad-Hoc Debug\" PROVISIONING_PROFILE=\"$PROFILE_UUID\" CODE_SIGN_IDENTITY=\"$DISTRIBUTION_IDENTITY\" CONFIGURATION_BUILD_DIR=\"$BUILD_DIRECTORY" clean build"

# Use this line if you want to build a standalone project
XCODE_BUILD_COMMAND="xcodebuild -sdk iphoneos${OS_VERSION} -project BSSCISample.xcodeproj -scheme \"BSSCISample-Ad-Hoc\" -configuration \"Ad-Hoc Debug\" PROVISIONING_PROFILE=\"$PROFILE_UUID\" CODE_SIGN_IDENTITY=\"$DISTRIBUTION_IDENTITY\" CONFIGURATION_BUILD_DIR=$BUILD_DIRECTORY clean build"


# Determine the current git commit hash
GIT_VERSION=$(/usr/bin/git log -1 --format="%H")

# Set the bundle version to the current git commit hash
$(/usr/libexec/PlistBuddy -c "Set :CFBundleVersion \"${BUILD_NUMBER}_${GIT_VERSION}\"" $PLIST_PATH)


# Run the xcode command
eval $XCODE_BUILD_COMMAND


# Change into the build output directory
cd "$BUILD_DIRECTORY" || die "Build directory does not exist."

# Search for the generated .app file
for APP_FILENAME in *.app; do
	APP_NAME=$(echo "$APP_FILENAME" | sed -e 's/.app//')
	IPA_FILENAME="$APP_NAME.ipa"
	DSYM_FILEPATH="$APP_FILENAME.dSYM"

	# Archive the application and sign it with the specified distribution certificate
	/usr/bin/xcrun -sdk iphoneos PackageApplication -v "$APP_FILENAME" -o "$BUILD_DIRECTORY/$IPA_FILENAME" --sign "$DISTRIBUTION_IDENTITY" --embed "$PROVISIONING_PROFILE_PATH"
done


# Revert the changes to the Info.plist
git checkout -- "$PLIST_PATH"


# Decide if you want to create the tag here or let Jenkins do that

# Tag the current git commit with the generated build number and push the tags for that commit
#CURRENT_TIMESTAMP=$(date '+%D %T')
#git tag -a "build_${BUILD_NUMBER}_${GIT_VERSION}" -m "Build ${BUILD_NUMBER}_${GIT_VERSION} ${CURRENT_TIMESTAMP}"
#git push --tags
