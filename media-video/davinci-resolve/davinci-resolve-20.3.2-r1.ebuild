# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MAJOR_VER="$(ver_cut 1-3)"
#MAJOR_VER="20.0b2"
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
SRC_URI="${ARC_NAME}
	https://www.danieltufvesson.com/download/?file=makeresolvedeb/makeresolvedeb_${MRD_VER}_multi.sh.tar.gz"

LICENSE="all-rights-reserved"
KEYWORDS="-* ~amd64"
SLOT="0"
IUSE="doc udev +system-glib"

RESTRICT="strip mirror bindist fetch userpriv"

RDEPEND="
	virtual/glu
	x11-libs/gtk+:=
	virtual/libcrypt:=
	${CONFLICT_PKG}
"

DEPEND="
	dev-libs/apr-util
	app-arch/libarchive
	dev-libs/openssl-compat
	media-libs/gstreamer
	media-libs/libpng
	sys-fs/fuse[suid]
	udev? ( virtual/udev )
	virtual/opencl
	x11-misc/xdg-user-dirs
	dev-qt/qtcore
	dev-qt/qtsvg
	dev-qt/qtwebengine
	dev-qt/qtwebsockets
	dev-qt/qtvirtualkeyboard
	${RDEPEND}
"

BDEPEND="dev-util/patchelf"

S="${WORKDIR}"
DR="${WORKDIR}/davinci-resolve_${MAJOR_VER}-mrd${MRD_VER}_amd64"

QA_PREBUILT="*"

pkg_nofetch() {
	einfo "Please download installation file"
	einfo "  - ${ARC_NAME}"
	einfo "from ${HOMEPAGE} and place it in ${DISTDIR}."
	einfo "===="
	einfo "Please download installation file"
	einfo "  - makeresolvedeb_${MRD_VER}_multi.sh.tar.gz"
	einfo "from https://www.danieltufvesson.com/makeresolvedeb and place it in \$\{DISTDIR\}."
}

src_prepare() {
	mv "${WORKDIR}"/makeresolvedeb*.sh "${WORKDIR}"/makeresolvedeb.sh
	eapply -p0 "${FILESDIR}/makeresolvedeb_gentoo_${MRD_VER}.patch"

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
	pushd ${DR}/opt/resolve/
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
		_patchelf_paths[${_index}]="/opt/resolve/${_patchelf_paths[${_index}]}"
	done

	while IFS= read -r -d '' _file; do
	    [[ -f "${_file}" && $(od -t x1 -N 4 "${_file}") == *"7f 45 4c 46"* ]] || continue
	    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "${_file}"
	done < <(find "${DR}" -type f -size -32M -print0)

#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./Fairlight Studio Utility/libc++abi.so.1" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciKeyboards/lib/libc++abi.so.1" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./DaVinci Control Panels Setup/AdminUtility/PlugIns/FairlightPanels/lib/libc++abi.so.1" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciPanels/lib/libc++abi.so.1" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./DaVinci Control Panels Setup/libc++abi.so.1" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libxmlsec1-openssl.so" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libwebpdecoder.so.3.1.10" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libcrypto.so.1.1" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libssl.so.1.1" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libsharpyuv.so.0.1.1" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libCrmSdk.so.2.10" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libcurl.so" || die
#	patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./libs/libc++abi.so.1" || die
	popd
}

src_install() {
	cp -a ${DR}/lib "${ED}" || die
	cp -a ${DR}/opt "${ED}" || die
	cp -a ${DR}/usr "${ED}" || die
	cp -a ${DR}/var "${ED}" || die

	if use doc ; then
		dodoc *.pdf
	fi

	# See bug 718070 for reason for the next line.
	if use system-glib ; then
		rm -f "${ED}"/opt/resolve/libs/libglib-*
		rm -f "${ED}"/opt/resolve/libs/libgio-2.0.so*
		rm -f "${ED}"/opt/resolve/libs/libgmodule-2.0.so*
        fi

	install -D -m 0644 -t "${ED}"/opt/resolve/configs \
	    ""${ED}"/opt/resolve/share/default-config.dat" \
	    ""${ED}"/opt/resolve/share/log-conf.xml"
	install -D -m 0644 -t "${ED}"/opt/resolve/DolbyVision \
	    "${ED}"/opt/resolve/share/default_cm_config.bin

	keepdir "/opt/resolve/.license"
	keepdir "/opt/resolve/Apple Immersive/Calibration"
	keepdir "/opt/resolve/Extras"
	keepdir "/opt/resolve/Fairlight"
	keepdir "/opt/resolve/easyDCP"
	keepdir "/opt/resolve/logs"
	keepdir "/var/BlackmagicDesign/DaVinci Resolve"
}

pkg_preinst() {
	xdg_pkg_preinst
}

pkg_postinst() {
	xdg_pkg_postinst
	udev_reload
}

pkg_postrm() {
	xdg_pkg_postrm
	udev_reload
}

