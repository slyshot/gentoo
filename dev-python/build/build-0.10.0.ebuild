# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=flit
PYTHON_COMPAT=( python3_{9..11} pypy3 )

inherit distutils-r1 multiprocessing

DESCRIPTION="A simple, correct PEP517 package builder"
HOMEPAGE="
	https://pypi.org/project/build/
	https://github.com/pypa/build/
"
SRC_URI="
	https://github.com/pypa/build/archive/${PV}.tar.gz -> ${P}.gh.tar.gz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~ia64 ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"

RDEPEND="
	>=dev-python/packaging-19.0[${PYTHON_USEDEP}]
	dev-python/pyproject-hooks[${PYTHON_USEDEP}]
	$(python_gen_cond_dep '
		>=dev-python/tomli-1.1.0[${PYTHON_USEDEP}]
	' 3.{8..10})
"
BDEPEND="
	test? (
		>=dev-python/filelock-3[${PYTHON_USEDEP}]
		>=dev-python/pytest-mock-2[${PYTHON_USEDEP}]
		>=dev-python/pytest-rerunfailures-9.1[${PYTHON_USEDEP}]
		>=dev-python/pytest-xdist-1.34[${PYTHON_USEDEP}]
		>=dev-python/setuptools-56.0.0[${PYTHON_USEDEP}]
		>=dev-python/wheel-0.36.0[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest

python_test() {
	local EPYTEST_DESELECT=(
		# broken by the presence of flit_core
		tests/test_util.py::test_wheel_metadata_isolation
		# broken by the presence of virtualenv (it changes the error
		# messages, sic!)
		'tests/test_main.py::test_output[via-sdist-isolation]'
		'tests/test_main.py::test_output[wheel-direct-isolation]'
		# Internet
		tests/test_main.py::test_build_package
		tests/test_main.py::test_build_package_via_sdist
		tests/test_self_packaging.py::test_build_sdist
		tests/test_self_packaging.py::test_build_wheel
		'tests/test_util.py::test_wheel_metadata[True]'
		tests/test_util.py::test_with_get_requires
		# we don't really have to test that fallback
		# (requires dev-python/toml that we'd like to lastrite eventually)
		tests/test_projectbuilder.py::test_toml_instead_of_tomli
	)

	epytest -p no:flaky -n "$(makeopts_jobs)"
}
