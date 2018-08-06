FROM openjdk:8-jdk-stretch

RUN apt-get update
RUn apt-get install -y python python-pip python-virtualenv wget awscli

ENV SDK_VERSION     25.2.5
ENV ANDROID_HOME    /opt/android-sdk
ENV SDK_UPDATE      tools,platform-tools,build-tools-27.0.3,android-27,android-26,android-23
ENV LD_LIBRARY_PATH ${ANDROID_HOME}/tools/lib64/qt:${ANDROID_HOME}/tools/lib/libQt5:$LD_LIBRARY_PATH/
ENV GRADLE_VERSION  4.4
ENV GRADLE_HOME     /opt/gradle-${GRADLE_VERSION}
ENV PATH            ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${GRADLE_HOME}/bin

RUN curl -SLO "https://dl.google.com/android/repository/tools_r${SDK_VERSION}-linux.zip"
RUN mkdir -p "${ANDROID_HOME}" \
    && unzip "tools_r${SDK_VERSION}-linux.zip" -d "${ANDROID_HOME}" \
    && rm -Rf "tools_r${SDK_VERSION}-linux.zip" \
    && echo y | ${ANDROID_HOME}/tools/android update sdk --filter ${SDK_UPDATE} --all --no-ui --force \
    && mkdir -p ${ANDROID_HOME}/tools/keymaps \
    && touch ${ANDROID_HOME}/tools/keymaps/en-us \
    # Licenses taken from https://github.com/mindrunner/docker-android-sdk
    && mkdir -p ${ANDROID_HOME}/licenses \
    && echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55\n" > ${ANDROID_HOME}/licenses/android-sdk-license \
    && echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd\n" > ${ANDROID_HOME}/licenses/android-sdk-preview-license \
    # Install gradle
    && curl -SLO https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && mkdir -p "${GRADLE_HOME}" \
    && unzip "gradle-${GRADLE_VERSION}-bin.zip" -d "/opt" \
    && rm -f "gradle-${GRADLE_VERSION}-bin.zip" 

RUN chmod -R 777 /opt/android-sdk
ADD . /${file-path}                       //edit to your own path(directory for you to put your file or application) on container.
WORKDIR /${file-path}                     //working directory on your file or application path.
RUN gradle $(assembleDebug)              //Your gradle command to build your apk file.  
RUN AWS_ACCESS_KEY_ID=$(cat access-key) AWS_SECRET_ACCESS_KEY=$(cat secret-key) aws s3 cp /android/app/build/{your-apps-output-path}/app-debug.apk s3://$(your-s3-bucket-name)/android/$(cat version.apps).apk
