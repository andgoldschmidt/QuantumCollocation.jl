# QuantumCollocation.jl

<div align="center"> <a href="https://github.com/aarontrowbridge/Piccolo.jl">
    <img src="assets/logo.svg" alt="logo" width="35%"/>
</a> </div>


<div align="center">

| **Documentation** | **Build Status** | **Support** | **Paper** |
|:-----------------:|:----------------:|:-----------:|:---------:|
| [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aarontrowbridge.github.io/QuantumCollocation.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aarontrowbridge.github.io/QuantumCollocation.jl/dev/) | [![Build Status](https://github.com/aarontrowbridge/QuantumCollocation.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/aarontrowbridge/QuantumCollocation.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/aarontrowbridge/QuantumCollocation.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/aarontrowbridge/QuantumCollocation.jl)| [![Unitary Fund](https://img.shields.io/badge/Supported%20By-Unitary%20Fund-FFFF00.svg)](https://unitary.fund) | [![arXiv](https://img.shields.io/badge/arXiv-2305.03261-b31b1b.svg)](https://arxiv.org/abs/2305.03261)

</div>


**QuantumCollocation.jl** uses [NamedTrajectories.jl](https://github.com/aarontrowbridge/NamedTrajectories.jl) to set up and solve direct collocation problems specific to quantum optimal control, i.e. generating a *pulse* sequence $a_{1:T-1}$ to drive a quantum system and realize a target gate $U_{\text{goal}}$. We formulate this problem as a nonlinear program (NLP) of the form

```math
\begin{aligned}
\underset{U_{1:T}, a_{1:T-1}}{\text{minimize}} & \quad \ell(U_T, U_{\text{goal}})\\
\text{ subject to } & \quad U_{t+1} = \exp(-i H(a_t)) U_t 
\end{aligned}
```

Where the dynamics between *knot points* $(U_t, a_t)$ and $(U_{t+1}, a_{t+1})$ are enforced as constraints on the states which are free variables in the solver; this optimization framework is called *direct collocation*.  For details of our implementation please see our award-winning paper [Direct Collocation for Quantum Optimal Control](https://arxiv.org/abs/2305.03261). 

QuantumCollocation.jl gives the user the ability to add other constraints and objective functions to this problem and solve it efficiently using [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl) and [MathOptInterface.jl](https://github.com/jump-dev/MathOptInterface.jl) under the hood.

## :warning: Notice :warning:

This package is under active development and issues may arise -- please be patient and report any issues you find!

## Installation

QuantumCollocation.jl is registered! To install:

```julia
using Pkg
Pkg.add(QuantumCollocation)
```

## Examples

### Single Qubit X-Gate
See the example script [examples/scripts/single_qubit_gate.jl](examples/scripts/single_qubit_gate.jl), which  produces the following plot:

![Single Qubit X-Gate](images/T_100_Q_1000_iter_1000_00004_fidelity_0.9999999999994745.png)

## Repo Structure

Uses GitHub Next's [repo-visualization](https://githubnext.com/projects/repo-visualization/) tool to see repo structure.

![Repo Structure](images/diagram.svg)

## TODO:

Documentation:

- [ ] cross-referencing to library
- [ ] notation explanation
- [ ] examples
  - [ ] two-qubit
  - [ ] cat qubit 
  - [ ] three-qubit 
  - [ ] qubit-cavity
  - [ ] qubit-cavity-qubit
- [ ] contributing guidelines

Functionality:

- [ ] custom `QuantumTrajectory` types (repr. of isomorphic states)
- [ ] better quantum system constructors (e.g. storing composite system info) 
