---
title: CS.077 GROMACS-LS and MDStress
show_meta: no
---
# About GROMACS-LS
## What is GROMACS-LS?
GROMACS-LS is a research fork of the widely used molecular dynamics simulation [GROMACS](https://www.gromacs.org) that aims
to implement local stress and elasticity calculations via the [MDStress Library](https://github.com/vanegasj/mdstress-library).

## Why GROMACS-LS?
GROMACS-LS offers simple stress and elasticity calculations that can be computed during a simulation, a feature which is missing from the base GROMACS software. 
Other highlights of GROMACS-LS:
- Uses the autodiff library to easily compute up to 4-body potentials
- Calculations for 1-, 2-, and 3-dimensional systems
- SIMD parallelized stress and elasticity calculations, minimizing additional simulation time
- Recently updated to be based on the 2025.4 branch of GROMACS (up from 2016.3)

## Demo video
[Link demo or include a photo of a test run here]

# How to use GROMACS-LS
Steps to install and use GROMACS-LS can be found on the GitHub page, [GROMACS-LS](https://github.com/vanegasj/gromacs-ls). The primary dependency for GROMACS-LS is the [MDStress library](https://github.com/vanegasj/mdstress-library).
Other dependencies include:
- FFTW3 (double precision, libfftw3.so)
- CMake
- Python 3 with Numpy and Scipy (to use the tensortools analysis tool)

# Team Members

## Capstone group
### Abdul Raziq
Abdul Raziq is a junior at Oregon State University studying Computer Science with a focus on performance engineering and scientific computing. His work centers on optimizing high-performance systems, including molecular dynamics simulations. As part of the GROMACS-LS capstone project, he contributes to performance optimization, SIMD acceleration, and integration with advanced libraries such as MDStress and etc

Portfolio: https://web.engr.oregonstate.edu/~razika/Personal%20Portfolio/
GitHub: https://github.com/ARB726
### Nathaniel Chappelle

### Joo Wang Lee

### Finlay Curtiss
Finlay is a senior at Oregon State University studying Computer Science and Environmental Science.

## Project partner
### Dr. Juan Vanegas
Associate Professor of Biochemistry & Biophysics at Oregon State University


