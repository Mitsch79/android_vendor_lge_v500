#!/usr/bin/env bash
set -euo pipefail

tree=$1
work=${V500_MESA23_WORK:-$HOME/android/v500-mesa-23.2.1}
mkdir -p "$work"/{packages,tools} "$tree/external/mesa3d-v500"
archive="$work/mesa-23.2.1.tar.xz"
if [[ ! -f "$archive" ]]; then
    curl --fail --location --retry 2 -o "$archive.incoming" https://archive.mesa3d.org/mesa-23.2.1.tar.xz
    mv "$archive.incoming" "$archive"
fi
printf '%s  %s\n' 64de0616fc2d801f929ab1ac2a4f16b3e2783c4309a724c8a259b20df8bbc1cc "$archive" | sha256sum -c -

if [[ ! -x "$work/tools/usr/bin/meson" || ! -x "$work/tools/usr/bin/ninja" || ! -d "$work/tools/usr/lib/python3/dist-packages/mako" ]]; then
    (
        cd "$work/packages"
        apt-get download meson ninja-build python3-mako python3-markupsafe
        for package in ./*.deb; do
            dpkg-deb -x "$package" "$work/tools"
        done
    )
fi

destination="$tree/external/mesa3d-v500"
if [[ ! -r "$destination/VERSION" ]]; then
    tar --strip-components=1 -xJf "$archive" -C "$destination"
fi
[[ $(cat "$destination/VERSION") == 23.2.1 ]]
cross_make="$destination/android/mesa3d_cross.mk"
if ! grep -Fq '$(V500_MESA23_TOOLS)' "$cross_make"; then
    sed -i \
        -e 's@PATH=/usr/bin:/usr/local/bin:\$\$PATH meson@PYTHONPATH=$(V500_MESA23_TOOLS)/usr/lib/python3/dist-packages PATH=$(V500_MESA23_TOOLS)/usr/bin:/usr/bin:$$PATH meson@' \
        -e 's@PATH=/usr/bin:/bin:/sbin:\$\$PATH ninja@PYTHONPATH=$(V500_MESA23_TOOLS)/usr/lib/python3/dist-packages PATH=$(V500_MESA23_TOOLS)/usr/bin:/usr/bin:/bin:$$PATH ninja@' \
        -e '/^[[:space:]]*-Dplatforms=android/a\	-Dandroid-libbacktrace=disabled                                              \\' \
        "$cross_make"
fi
# Mesa's DRI export map also lists symbols from unselected Gallium drivers.
if ! grep -Fq -- '-Wl,--undefined-version' "$cross_make"; then
    sed -i 's/-Wl,-e,main/-Wl,--undefined-version/' "$cross_make"
fi
# The cross-file strips inherited build-id flags. Explicitly emit the SHA-1 ID
# expected by Freedreno's shader cache, independent of Meson's link probe.
if ! grep -Fq -- "'-Wl,--build-id=sha1'" "$cross_make"; then
    sed -i '/"c_link_args = \[/s/\[\$(foreach/[\x27-Wl,--build-id=sha1\x27, $(foreach/; /"cpp_link_args = \[/s/\[\$(foreach/[\x27-Wl,--build-id=sha1\x27, $(foreach/' "$cross_make"
fi
# Android 14 stages vendor.img from the declared install list.
android_make="$destination/android/Android.mk"
if ! grep -Fq 'msm_dri.so' "$android_make"; then
    sed -i 's/^LOCAL_MODULE_SYMLINKS := \$1\$2$/& $(if $(filter libgallium_dri,$1),msm_dri.so kms_swrast_dri.so swrast_dri.so)/' "$android_make"
fi
selection="V500_MESA23_TOOLS := $work/tools"
selection_file="$tree/device/lge/v500/mesa23.mk"
if [[ ! -f "$selection_file" || $(cat "$selection_file") != "$selection" ]]; then
    printf '%s\n' "$selection" > "$selection_file"
fi
