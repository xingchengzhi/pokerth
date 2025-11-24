Best practice is to use the VS Code Dev-Container feature.

Inside of the container:

`cd ${ROOT}/pokerth`
`bash docker/android/build_android.sh`

The APK will then be available in: `${ROOT}/pokerth/build-android-x86_64/android-build/build/outputs/apk/release/android-build-release-unsigned.apk`

... sign it:

`keytool -genkey -v -keystore my.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias app`
`apksigner sign --ks my.keystore --ks-key-alias app ${ROOT}/pokerth/build-android-x86_64/android-build/build/outputs/apk/release/android-build-release-unsigned.apk`

