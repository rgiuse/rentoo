# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# MAJOR_VER="$(ver_cut 1-3)"
MAJOR_VER="20.3.1"
if [[ "${PN}" == "davinci-resolve-studio" ]] ; then
	BASE_NAME="DaVinci_Resolve_Studio_${MAJOR_VER}_Linux"
	CONFLICT_PKG="!!media-video/davinci-resolve"
else
	BASE_NAME="DaVinci_Resolve_${MAJOR_VER}_Linux"
	CONFLICT_PKG="!!media-video/davinci-resolve-studio"
fi
ARC_NAME="${BASE_NAME}.zip"
MRD_VER=1.8.3
inherit udev xdg

DESCRIPTION="Professional A/V post-production software suite"
HOMEPAGE="
	https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion
"
DL_DAVINCI_URL="https://www.blackmagicdesign.com/event/davinciresolvedownload"
SRC_URI="${ARC_NAME}"
# https://www.danieltufvesson.com/download/?file=makeresolvedeb/makeresolvedeb_${MRD_VER}_multi.sh.tar.gz

LICENSE="all-rights-reserved"
KEYWORDS="-* ~amd64"
SLOT="0"
IUSE="doc udev +system-glib"

RESTRICT="strip mirror bindist fetch userpriv"

REQUIRES_EXCLUDE="libpng12.so.0 libreadline.so.6 libsonyxavcenc.so libQt5VirtualKeyboard.so.5 libQt5VirtualKeyboard.so.5 libQt5RemoteObjects.so.5 libQt5Bodymovin.so.5 libstdc++.so.5 libstdc++-libc6.2-2.so.3 libc++.so.1 libc++abi.so.1"

RDEPEND="
	virtual/glu
	x11-libs/gtk+:=
	virtual/libcrypt:=
	${CONFLICT_PKG}
"

	# dev-qt/qtcore:5
	# dev-qt/qtsvg:5
	# dev-qt/qtwebengine:5
	# dev-qt/qtwebsockets:5
	# dev-qt/qtvirtualkeyboard:5
DEPEND="
	dev-libs/apr-util
	app-arch/libarchive
	dev-libs/openssl-compat
	media-libs/gstreamer
	media-libs/libpng
    sys-apps/fakeroot
    app-arch/dpkg
    dev-qt/qtbase:6
    dev-qt/qtdeclarative
    net-dns/avahi
    dev-libs/libusb
    sys-libs/glibc
    media-libs/libwebp
    app-crypt/mit-krb5
    dev-libs/log4cxx
    dev-libs/openssl-compat
    net-misc/curl
    dev-libs/xmlsec
	sys-fs/fuse[suid]
	udev? ( virtual/udev )
	virtual/opencl
	x11-misc/xdg-user-dirs
	${RDEPEND}
"

BDEPEND="dev-util/patchelf"

S="${WORKDIR}"
DR="${WORKDIR}/davinci-resolve_${MAJOR_VER}-mrd${MRD_VER}_amd64"
INSTALL_DIR="/opt/resolve/"
FLOG_DIR="/var/log/davinci-resolve"

QA_PREBUILT="*"

pkg_nofetch() {
	einfo "Please download installation file"
	einfo "  - ${ARC_NAME}"
	einfo "from ${DL_DAVINCI_URL} and place it in DISTDIR (usually /var/cache/distfiles : https://wiki.gentoo.org/wiki//var/cache/distfiles)."
}

src_prepare() {
    cp "${FILESDIR}/makeresolvedeb_${MRD_VER}_multi.sh" "${WORKDIR}"/makeresolvedeb.sh
    if [ -e "${FILESDIR}/makeresolvedeb_gentoo_${MRD_VER}.patch" ]; then
        eapply -p0 "${FILESDIR}/makeresolvedeb_gentoo_${MRD_VER}.patch"
    fi

	eapply_user

	sed -i -e "s!#LIBDIR#!$(get_libdir)!" "${WORKDIR}"/makeresolvedeb.sh || die "Sed failed!"
}

_adjust_sandbox() {
	addwrite /dev
	addread /dev
	addpredict /root
	addpredict /etc
	addpredict /lib
	addpredict /usr
	addpredict /sys
	addpredict "/var/BlackmagicDesign"
	addpredict "/var/BlackmagicDesign/DaVinci Resolve"
}

src_compile() {
	_adjust_sandbox
	cd "${WORKDIR}"
	chmod u+x ${BASE_NAME}.run
	CI_TEST="1" "${WORKDIR}"/makeresolvedeb.sh ${BASE_NAME}.run
    mv "${DR}/usr/lib/libFairlightPanelAPI.so" "${T}/libFairlightPanelAPI.so"
    mv "${DR}/usr/lib/libDaVinciPanelAPI.so" "${T}/libDaVinciPanelAPI.so"
}

src_install() {
	cp -a ${DR}/lib "${ED}" || die
	cp -a ${DR}/opt "${ED}" || die
	cp -a ${DR}/usr "${ED}" || die
	cp -a ${DR}/var "${ED}" || die
    
    rm -rf "${ED}/var/BlackmagicDesign"
    
	if use doc ; then
		dodoc *.pdf
	fi

	# See bug 718070 for reason for the next line.
	if use system-glib ; then
		rm -f "${ED}${INSTALL_DIR}"libs/libglib-*
		rm -f "${ED}${INSTALL_DIR}"libs/libgio-2.0.so*
		rm -f "${ED}${INSTALL_DIR}"libs/libgmodule-2.0.so*
    fi
    dolib.so "${T}/libFairlightPanelAPI.so"
    dolib.so "${T}/libDaVinciPanelAPI.so"
    chmod 777 "${ED}${INSTALL_DIR}"
    cd "${ED}${INSTALL_DIR}"
    _patchelf_paths=(  "libs"
                       "libs/plugins/sqldrivers"
                       "libs/plugins/xcbglintegrations"
                       "libs/plugins/imageformats"
                       "libs/plugins/platforms"
                       "libs/Fusion"
                       "plugins"
                       "bin"
                       "BlackmagicRAWSpeedTest/BlackmagicRawAPI"
                       "BlackmagicRAWSpeedTest/plugins/platforms"
                       "BlackmagicRAWSpeedTest/plugins/imageformats"
                       "BlackmagicRAWSpeedTest/plugins/mediaservice"
                       "BlackmagicRAWSpeedTest/plugins/audio"
                       "BlackmagicRAWSpeedTest/plugins/xcbglintegrations"
                       "BlackmagicRAWSpeedTest/plugins/bearer"
                       "BlackmagicRAWPlayer/BlackmagicRawAPI"
                       "BlackmagicRAWPlayer/plugins/mediaservice"
                       "BlackmagicRAWPlayer/plugins/imageformats"
                       "BlackmagicRAWPlayer/plugins/audio"
                       "BlackmagicRAWPlayer/plugins/platforms"
                       "BlackmagicRAWPlayer/plugins/xcbglintegrations"
                       "BlackmagicRAWPlayer/plugins/bearer"
                       "Onboarding/plugins/xcbglintegrations"
                       "Onboarding/plugins/qtwebengine"
                       "Onboarding/plugins/platforms"
                       "Onboarding/plugins/imageformats"
                       "DaVinci Control Panels Setup/plugins/platforms"
                       "DaVinci Control Panels Setup/plugins/imageformats"
                       "DaVinci Control Panels Setup/plugins/bearer"
                       "DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciKeyboards"
                       "DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciPanels")
    for _index in "${!_patchelf_paths[@]}"
    do
        _patchelf_paths[${_index}]="${INSTALL_DIR}/${_patchelf_paths[${_index}]}"
    done
    
    #while IFS= read -r -d '' _file; do
    #    [[ -f "${_file}" && $(od -t x1 -N 4 "${_file}") == *"7f 45 4c 46"* ]] || continue
    #    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "${_file}"
    #done < <(find "squashfs-root" -type f -size -32M -print0)
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./Fairlight Studio Utility/libc++abi.so.1" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciKeyboards/lib/libc++abi.so.1" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./DaVinci Control Panels Setup/AdminUtility/PlugIns/FairlightPanels/lib/libc++abi.so.1" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciPanels/lib/libc++abi.so.1" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./DaVinci Control Panels Setup/libc++abi.so.1" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libxmlsec1-openssl.so" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libwebpdecoder.so.3.1.10" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libcrypto.so.1.1" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libssl.so.1.1" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libsharpyuv.so.0.1.1" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libCrmSdk.so.2.10" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libcurl.so" || die
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libc++abi.so.1" || die
}

pkg_preinst() {
	xdg_pkg_preinst
}

pkg_postinst() {
	xdg_pkg_postinst
	udev_reload
    mkdir -p "/var/BlackmagicDesign/DaVinci Resolve"
    chmod -R 777 "/var/BlackmagicDesign"
    mkdir -p "${FLOG_DIR}"
    chmod 777 "${FLOG_DIR}"
    ln -s "${FLOG_DIR}" "${INSTALL_DIR}"/logs
}

pkg_prerm() {
    rm -rf "${INSTALL_DIR}"Apple\ Immersive
    rm -rf "${INSTALL_DIR}"Extras
    rm -rf "${INSTALL_DIR}"Fairlight
    if [ -L "${INSTALL_DIR}"logs ]; then
        rm -f "${INSTALL_DIR}"logs
    else
        rm -rf "${INSTALL_DIR}"logs
    fi
    rm -rf "/var/BlackmagicDesign"

}

pkg_postrm() {
	xdg_pkg_postrm
	udev_reload
}

