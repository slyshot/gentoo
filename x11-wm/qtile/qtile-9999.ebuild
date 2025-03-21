# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{9..11} )

inherit distutils-r1 virtualx

DESCRIPTION="A full-featured, hackable tiling window manager written in Python"
HOMEPAGE="http://qtile.org/"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/qtile/qtile.git"
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64"
fi

LICENSE="MIT"
SLOT="0"
IUSE="pulseaudio wayland"

RDEPEND="
	>=dev-python/cairocffi-0.9.0[${PYTHON_USEDEP}]
	>=dev-python/cffi-1.1.0[${PYTHON_USEDEP}]
	dev-python/dbus-next[${PYTHON_USEDEP}]
	dev-python/pygobject[${PYTHON_USEDEP}]
	>=dev-python/six-1.4.1[${PYTHON_USEDEP}]
	>=dev-python/xcffib-0.10.1[${PYTHON_USEDEP}]
	x11-libs/cairo[X,xcb(+)]
	x11-libs/libnotify[introspection]
	x11-libs/pango
	pulseaudio? (
		media-sound/pulseaudio
	)
	wayland? (
		dev-python/pywlroots[${PYTHON_USEDEP}]
	)
"
BDEPEND="
	dev-python/setuptools_scm[${PYTHON_USEDEP}]
	test? (
		media-gfx/imagemagick[X]
		x11-base/xorg-server[xephyr]
	)
"

EPYTEST_DESELECT=(
	# Can't find built qtile like migrate
	test/test_qtile_cmd.py::test_qtile_cmd
	test/test_qtile_cmd.py::test_display_kb
)

EPYTEST_IGNORE=(
	# Tries to find binary and fails; not worth running anyway?
	test/test_migrate.py
)

distutils_enable_tests pytest

python_prepare_all() {
	# Avoid automagic dependency on libpulse
	if ! use pulseaudio ; then
		sed -i -e 's/call("libpulse", "--libs")/throw PkgConfigError/' setup.py || die
	fi

	# Avoid automagic dependency on pywlroots
	if ! use wayland ; then
		sed -i -e 's/import wlroots.ffi_build/raise ImportError/' setup.py || die
	fi

	distutils-r1_python_prepare_all
}

src_test() {
	virtx distutils-r1_src_test
}

python_test() {
	# Force usage of built module
	rm -rf "${S}"/libqtile || die

	epytest --backend=x11 $(usev wayland '--backend=wayland') || die "Tests failed with ${EPYTHON}"
}

python_install_all() {
	local DOCS=( CHANGELOG README.rst )
	distutils-r1_python_install_all

	insinto /usr/share/xsessions
	doins resources/qtile.desktop

	insinto /usr/share/wayland-sessions
	doins resources/qtile-wayland.desktop

	exeinto /etc/X11/Sessions
	newexe "${FILESDIR}"/${PN}-session-r1 ${PN}
}
