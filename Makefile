PREFIX ?= $(HOME)
FC = ifort
FFLAGS2 =
BIT = $(shell if [ `uname -m` = "i686" ]; then echo "32"; else echo "64"; fi)
QDYNDEBUG ?= 0

ifeq ($(QDYNDEBUG),0)
  ifeq ($(FC),ifort)
	FFLAGS ?= -O3 -openmp
  endif
  ifeq ($(FC),gfortran)
	FFLAGS ?= -O3 -openmp -fopenmp
  endif
  ifeq ($(FC),xlf)
	FFLAGS ?= -O3 -qxlf90 -qessl
  endif
  ifeq ($(FC),xlf_r)
	FFLAGS ?= -O3 -qsmp=omp:auto -qnosave -qxlf90 -qessl
  endif
endif
ifeq ($(QDYNDEBUG),1)
  ifeq ($(FC),ifort)
	FFLAGS ?= -O0 -g -openmp
  endif
  ifeq ($(FC),gfortran)
	FFLAGS ?= -O0 -g -openmp -fopenmp
  endif
  ifeq ($(FC),xlf)
	FFLAGS ?= -O0 -g -qxlf90 -qessl -qfullpath
  endif
  ifeq ($(FC),xlf_r)
	FFLAGS ?= -O0 -g -qsmp=omp:auto -qnosave -qxlf90 -qessl -qfullpath
  endif
endif
ifeq ($(QDYNDEBUG),2)
  ifeq ($(FC),ifort)
	FFLAGS ?= -O0 -g -warn all -check all -debug all -traceback -openmp -fpe-all=0
  endif
  ifeq ($(FC),gfortran)
	FFLAGS ?= -O0 -g -Wall -fbounds-check -fopenmp -ffpe-trap=invalid,zero,overflow
  endif
  ifeq ($(FC),xlf)
	FFLAGS ?= -O0 -qxlf90 -qessl -g -qcheck -qsigtrap==xl__trcedump -qflttrap=overflow:underflow:zerodivide:invalid:enable -qinitauto=FF -qfullpath
  endif
  ifeq ($(FC),xlf_r)
	FFLAGS ?= -O0 -qsmp=omp:auto -qnosave -qxlf90 -qessl -g -qcheck -qsigtrap==xl__trcedump -qflttrap=overflow:underflow:zerodivide:invalid:enable -qinitauto=FF -qfullpath
  endif
endif
FFLAGS += $(FFLAGS2)
FFLAGS += -I$(PREFIX)/lib/qdyn/mod/$(BIT) -L$(PREFIX)/lib/qdyn/mod/$(BIT) -L$(PREFIX)/lib/qdyn
LAPACK = lapack
BLAS = blas
SFFT = sfftpack$(BIT)
DFFT = dfftpack$(BIT)
SLATEC = slatec$(BIT)
LBFGSB = lbfgsb$(BIT)
QDYN = qdyn$(BIT)
LDFLAGS = -l$(QDYN) -l$(LAPACK) -l$(BLAS) -l$(SFFT) -l$(DFFT) -l$(SLATEC) -l$(LBFGSB) $(LIBS)

OBJ = fmo_globals.o open_close.o

# How to make object files from Fortran 90 files.
%.o: %.f90
	$(FC) $(FFLAGS) -c -o $@ $<

# How to make object files from Fortran 77 files.
%.o: %.f %.for
	$(FC) $(FFLAGS) -c -o $@ $<

all:  fmo_write_pulses fmo_prop  fmo_oct

install: all
	mkdir -p $(PREFIX)/bin
	cp fmo_write_pulses $(PREFIX)/bin/fmo_write_pulses
	cp fmo_prop $(PREFIX)/bin/fmo_prop
	cp fmo_oct $(PREFIX)/bin/fmo_oct

uninstall:
	rm -f $(PREFIX)/bin/fmo_write_pulses
	rm -f $(PREFIX)/bin/fmo_prop
	rm -f $(PREFIX)/bin/fmo_oct

precomp:
	@perl ./fill_version.pl FMO

fmo_write_pulses: precomp $(OBJ) fmo_write_pulses.o
	$(FC) $(FFLAGS) -o $@ $(OBJ) fmo_write_pulses.o $(LDFLAGS)

fmo_prop: precomp $(OBJ) fmo_prop.o
	$(FC) $(FFLAGS) -o $@ $(OBJ) fmo_prop.o $(LDFLAGS)

fmo_oct: precomp $(OBJ) fmo_oct.o
	$(FC) $(FFLAGS) -o $@ $(OBJ) fmo_oct.o $(LDFLAGS)


clean:
	rm -f *.o
	rm -f *.mod
	rm -f fmo_prop
	rm -f fmo_oct
	rm -f fmo_write_pulses
	rm -f VERSION.fi

.PHONY: clean
