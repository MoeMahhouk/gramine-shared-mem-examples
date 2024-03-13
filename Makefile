# Build shared_memory as follows:
#
# - make               -- create non-SGX no-debug-log manifest
# - make SGX=1         -- create SGX no-debug-log manifest
# - make SGX=1 DEBUG=1 -- create SGX debug-log manifest
#
# Any of these invocations clones shared_memory' git repository and builds shared_memory in
# default configuration.
#
# Use `make clean` to remove Gramine-generated files and `make distclean` to
# additionally remove the cloned shared_memory git repository.

################################# CONSTANTS ###################################

# directory with arch-specific libraries, used by shared_memory
# the below path works for Debian/Ubuntu; for CentOS/RHEL/Fedora, you should
# overwrite this default like this: `ARCH_LIBDIR=/lib64 make`
ARCH_LIBDIR ?= /lib/$(shell $(CC) -dumpmachine)

ENCLAVE_SIZE ?= 512M
ENTRY_POINT ?= main2

ifeq ($(DEBUG),1)
GRAMINE_LOG_LEVEL = debug
else
GRAMINE_LOG_LEVEL = error
endif

.PHONY: all
all: shared_memory.manifest
ifeq ($(SGX),1)
all: shared_memory.manifest.sgx shared_memory.sig
endif

################################ shared_memory MANIFEST ###############################

# The template file is a Jinja2 template and contains almost all necessary
# information to run shared_memory under Gramine / Gramine-SGX. We create
# shared_memory.manifest (to be run under non-SGX Gramine) by replacing variables
# in the template file using the "gramine-manifest" script.

RA_TYPE		?= dcap
ISVPRODID	?= 0
ISVSVN		?= 0

shared_memory.manifest: shared_memory.manifest.template
	gramine-manifest \
		-Dlog_level=$(GRAMINE_LOG_LEVEL) \
		-Darch_libdir=$(ARCH_LIBDIR) \
		-Dentrypoint=$(ENTRY_POINT) \
		-Dra_type=$(RA_TYPE) \
		-Disvprodid=$(ISVPRODID) \
		-Disvsvn=$(ISVSVN) \
		-Denclave_size=$(ENCLAVE_SIZE) \
		$< >$@

# Manifest for Gramine-SGX requires special "gramine-sgx-sign" procedure. This
# procedure measures all shared_memory trusted files, adds the measurement to the
# resulting manifest.sgx file (among other, less important SGX options) and
# creates shared_memory.sig (SIGSTRUCT object).

# Make on Ubuntu <= 20.04 doesn't support "Rules with Grouped Targets" (`&:`),
# see the gramine helloworld example for details on this workaround.
shared_memory.manifest.sgx shared_memory.sig: sgx_sign
	@:

.INTERMEDIATE: sgx_sign
sgx_sign: shared_memory.manifest
	gramine-sgx-sign \
		--manifest $< \
		--output $<.sgx


############################## RUNNING TESTS ##################################

.PHONY: check
check: all
	./run-tests.sh > TEST_STDOUT 2> TEST_STDERR
	@grep -q "Success 1/4" TEST_STDOUT
	@grep -q "Success 2/4" TEST_STDOUT
	@grep -q "Success 3/4" TEST_STDOUT
	@grep -q "Success 4/4" TEST_STDOUT
ifeq ($(SGX),1)
	@grep -q "Success SGX quote" TEST_STDOUT
endif

################################## CLEANUP ####################################

.PHONY: clean
clean:
	$(RM) main1 main2 *.manifest *.manifest.sgx *.sig *.args OUTPUT* *.PID TEST_STDOUT TEST_STDERR

.PHONY: build
build:
	gcc -o main1 main.c -lrt
	gcc -o main2 main2.c -lrt