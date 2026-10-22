# Android Release Signing

Debug builds still use Android's development key. Release builds now require an
operator-owned signing key; the old automatic debug-key fallback has been removed.
Do not distribute a debug APK as a production release.

Set these environment variables in your private build session or CI secret store:

| Variable | Meaning |
| --- | --- |
| `PIXELSEARCH_KEYSTORE_PATH` | Absolute path to the private release keystore |
| `PIXELSEARCH_KEYSTORE_PASSWORD` | Keystore password |
| `PIXELSEARCH_KEY_ALIAS` | Release/upload key alias |
| `PIXELSEARCH_KEY_PASSWORD` | Key password |

Then run `flutter build appbundle --release` or `flutter build apk --release`.
Missing credentials fail the release signing task instead of using a development
certificate. Keep the keystore outside this repository, back it up securely, and
do not put passwords in source files, screenshots, shell history, or chat messages.
Never supply Android's debug keystore as the release key.

Changing from a debug certificate to a release certificate normally prevents an
in-place update of an existing debug installation. Do not uninstall a user's app
to work around this without their approval: uninstalling removes local data.
No keys were generated and no installed app was replaced by the security review.

See [Android app signing](https://developer.android.com/studio/publish/app-signing)
for key custody and Play App Signing options.
