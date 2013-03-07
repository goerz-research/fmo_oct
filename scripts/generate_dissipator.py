#! /usr/bin/env python
from numpy import tan, pi
import argparse
import numpy as np
import scipy.linalg

from generate_config import H_system


def tensor_to_super(R_tensor):
    N = len(R_tensor)
    R_matrix = np.empty((N ** 2, N ** 2), dtype=complex)
    for i in xrange(N):
        for j in xrange(N):
            R_matrix[i::N, j::N] = R_tensor[i, :, j, :]
    return R_matrix


def operator_1_to_01(operator1):
    """Convert single-excitation subspace operator to 0,1-excitation subspace"""
    N = len(operator1)
    operator01 = np.zeros((N + 1, N + 1))
    operator01[1:, 1:] = operator1
    return operator01


def redfield_tensor(H_1, T, lmbda, gamma, secular=True):
    """Calculate the Redfield tensor elements R_{a,b,c,d}"""
    N = H_1.shape[0]
    H_x = operator_1_to_01(H_1)
    N_x = H_x.shape[0]
    E_x, U_x = scipy.linalg.eigh(H_x)

    K = np.empty((N, N_x, N_x))
    for n in xrange(N):
        H_sb_1 = np.zeros((N, N))
        H_sb_1[n, n] = 1
        H_sb_x = operator_1_to_01(H_sb_1)
        K[n] = U_x.T.dot(H_sb_x).dot(U_x)

    xi = np.einsum('nij,nkl->ijkl', K, K)

    E_diffs = np.array([[E_x[i] - E_x[j] for j in range(N_x)] for i in range(N_x)])
    cor = np.vectorize(cor_debye)(E_diffs, T, lmbda, gamma)

    Gamma = np.einsum('abcd,dc->abcd', xi, cor)

    I = np.identity(N_x)
    Gamma_summed = np.einsum('abbc->ac', Gamma)
    R = (np.einsum('ac,bd->abcd', I, Gamma_summed).conj() +
         np.einsum('bd,ac->abcd', I, Gamma_summed) +
         -np.einsum('cabd->abcd', Gamma).conj()
         - np.einsum('dbac->abcd', Gamma))

    if secular:
        secular_terms = 1 - ((1 - np.einsum('ij,kl->ijkl', I, I)) *
                             (1 - np.einsum('ik,jl->ijkl', I, I)))
        R *= secular_terms

    return R


def redfield_dissipator(H_system, *args, **kwargs):
    R = tensor_to_super(redfield_tensor(H_system, *args, **kwargs))
    H_x = operator_1_to_01(H_system)
    E_x, U_x = scipy.linalg.eigh(H_x)
    U_S = np.kron(U_x, U_x)
    R_sites = -1j * U_S.dot(R).dot(U_S.T)
    return R_sites


def cor_debye(x, T, lmbda, gamma, matsubara_cutoff=1000):
    """One-sided correlation function for Debye spectral density (JCP 112, 7953)"""
    if x == 0:
        return lmbda * (2*T/gamma - 1j)
    else:
        nu = 2 * pi * np.arange(matsubara_cutoff) * T
        return lmbda * gamma * ((1/tan(gamma/(2*T)) - 1j)/(gamma - 1j*x) +
                                4*T*np.sum(nu/(nu**2 - gamma**2)/(nu - 1j*x)))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="""
    Outputs all dissipation tensor elements in the site basis, for the FMO
    complex with the Brownian oscillator (Debye) spectral density. All units are
    in cm^-1.""")
    parser.add_argument('--temperature', default=53.55, type=float,
                        help='Temperature, default 53.55 (77 K)')
    parser.add_argument('--reorg-energy', default=35, type=float,
                        help='Reorganizaton energy, default 35 (set to zero '
                             'to turn off dissipation)')
    parser.add_argument('--cutoff-freq', default=106, type=float,
                        help='Cut-off frequency, default 106 (1/(50 fs))')
    parser.add_argument('--nonsecular', action='store_true',
                        help='Toggle to include non-secular terms')
    parser.add_argument('--output', default='dissipator',
                        help='Path to which to write -real and -imag output '
                             'files')

    args = parser.parse_args()

    R = redfield_dissipator(H_system, args.temperature,
                            args.reorg_energy, args.cutoff_freq,
                            not args.nonsecular)

    # convert to atomic units from wave numbers
    R *= 4.5563353e-06

    np.savetxt(args.output + '-real', R.real, '% e')
    np.savetxt(args.output + '-imag', R.imag, '% e')
