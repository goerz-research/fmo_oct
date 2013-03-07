#! /usr/bin/env python
from textwrap import dedent
import argparse
import numpy as np
import scipy.linalg
import sys


H_system = np.array(np.mat("""12400 -87.7 5.5 -5.9 6.7 -13.7 -9.9;
                              -87.7 12520 30.8 8.2 0.7 11.8 4.3;
                              5.5 30.8 12200 -53.5 -2.2 -9.6 6.;
                              -5.9 8.2 -53.5 12310 -70.7 -17. -63.3;
                              6.7 0.7 -2.2 -70.7 12470 81.1 -1.3;
                              -13.7 11.8 -9.6 -17. 81.1 12620 39.7;
                              -9.9 4.3 6. -63.3 -1.3 39.7 12430"""))

all_dipoles = np.array([d / scipy.linalg.norm(d) for d in
                        np.array([[3.019, 3.442, 0.797, 3.213,
                                   2.969, 0.547, 1.983],
                                  [2.284, -2.023, -3.871, 2.145,
                                   -2.642, 3.562, 2.837],
                                  [1.506, 0.431, 0.853, 1.112,
                                   -0.661, -1.851, 2.015]]).T])


def main(H_system, dipoles, target_site, rw_freq):
    N = len(H_system) + 1

    print dedent("""
    ! optimization for site {0} at rotating wave frequency {1}_cminv

    tgrid: n = 1
    1 : t_start = 0.0, t_stop = 300_fs, nt = 2000

    oct: iter_start = 1, iter_stop = 250, max_megs = 12000, type = krotovpk, &
       A = 0.0, B = 0, C = 0.0, iter_dat = oct_iters.dat

    pulse: n = 1
    1: type = gauss, t_start = 0.0, t_stop = 300_fs, E_0 = 1.0, &
       w_L = 0.0, id = 1, oct_increase_factor = 5.0, oct_outfile = pulse.dat, &
       oct_alpha = 1.0, oct_shape = sinsq, time_unit = fs

    psi: n = 8, system = rho_in
    1: type = const, a = 1.0
    2: type = const, a = 0.0
    3: type = const, a = 0.0
    4: type = const, a = 0.0
    5: type = const, a = 0.0
    6: type = const, a = 0.0
    7: type = const, a = 0.0
    8: type = const, a = 0.0

    psi: n = 8, system = rho_tgt""".format(target_site, rw_freq))

    for i in xrange(N):
        print "{0}: type = const, a = {1:f}".format(
            i + 1, 1.0 if i == target_site else 0.0)

    dipole_index = {'x': 0, 'y': 1, 'z': 2}

    for orient in 'xyz':
        dipoles = all_dipoles[:, dipole_index[orient]]

        print "\npot:  n = {0}, system = ham_{1}".format(N, orient)

        for i in xrange(N):
            print '{0:d}: type = const, surf = {0:d}, E_0 = {1:> e}_cminv'.format(
                i + 1, 0 if i == 0 else H_system[i - 1, i - 1] - rw_freq)

        print "\ndip: n = {0}, system = ham_{1}".format(N * (N - 1) / 2, orient)

        for n, (i, j) in enumerate((i, j) for i in xrange(N)
                                    for j in xrange(i + 1, N)):
            if i == 0:
                print ('{0: >2d}: type = const, surf1 =  1, surf2 = {1:d}, '
                        'mu_0 = {2: e}_cminv, pulse_id = 1').format(
                       n + 1, j + 1, 0 if j == 0 else dipoles[j - 1])
            else:
                print ('{0: >2d}: type = const, surf1 =  {1:d}, surf2 = {2:d}, '
                        'mu_0 = {3: e}_cminv').format(
                        n + 1, i + 1, j + 1, H_system[i - 1, j - 1])

    print dedent("""
    misc: mass = 1.0, base = exp, prop = newton, rk45_abserr = 1.0d-8, &
       rk45_relerr = 1.0d-8
    """)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default='config',
                        help='Path to which to write output file')
    parser.add_argument("--rw-freq", default=12500,
                        help='Rotating wave frequency (cm^-1)')
    parser.add_argument("--target-site", default=1)
    args = parser.parse_args()

    if args.output != 'stdout':
        sys.stdout = open(args.output, 'w')

    main(H_system, all_dipoles, args.target_site, args.rw_freq)
