# V500 vendor sources

This project prepares the V500-specific Mesa 23.2.1 build for LineageOS 21. It verifies the Mesa release archive by SHA-256, prepares the build tools and applies the three Freedreno/Android compatibility patches in a separate source directory.

The tablet portrait resource overlay aligns SetupDesign's header and content margins with the Lineage setup resources. On first boot, V500NavigationDefaults selects the standard navigation bar when the user has no saved taskbar preference. The user can subsequently enable the tablet taskbar in Settings.

From an Android source tree populated with the [V500 manifest](https://github.com/Mitsch79/android_local_manifests_v500/tree/lineage-21.0), run:

```sh
bash vendor/lge/v500/prepare-v500-vendor.sh "$PWD"
```

The first run needs network access, APT and an Ubuntu-compatible build environment. It writes the generated Mesa tool path to `device/lge/v500/mesa23.mk`. Keep locally extracted A300 firmware outside Git.
