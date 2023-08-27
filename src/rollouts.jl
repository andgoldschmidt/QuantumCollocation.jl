module Rollouts

export rollout
export unitary_rollout
export unitary_geodesic
export skew_symmetric
export skew_symmetric_vec
export linear_interpolation

using ..QuantumUtils
using ..QuantumSystems
using ..Integrators

using ExponentialAction
using LinearAlgebra
using Manifolds
using NamedTrajectories


function rollout(
    ψ̃₁::AbstractVector{Float64},
    controls::AbstractMatrix{Float64},
    Δt::Union{AbstractVector{Float64}, AbstractMatrix{Float64}, Float64},
    system::QuantumSystem;
    action=Integrators.fourth_order_pade
)
    if Δt isa AbstractMatrix
        @assert size(Δt, 1) == 1
        Δt = vec(Δt)
    elseif Δt isa Float64
        Δt = fill(Δt, size(controls, 2))
    end

    T = size(controls, 2)

    Ψ̃ = zeros(length(ψ̃₁), T)

    Ψ̃[:, 1] .= ψ̃₁

    for t = 2:T
        aₜ₋₁ = controls[:, t - 1]
        Gₜ = Integrators.G(
            aₜ₋₁,
            system.G_drift,
            system.G_drives
        )
        Ψ̃[:, t] .= action(Δt[t - 1], Gₜ, Ψ̃[:, t - 1])
    end

    return Ψ̃
end

rollout(ψ::Vector{<:Complex}, args...; kwargs...) =
    rollout(ket_to_iso(ψ), args...; kwargs...)

function rollout(
    ψ̃₁s::AbstractVector{<:AbstractVector}, args...; kwargs...
)
    return vcat([rollout(ψ̃₁, args...; kwargs...) for ψ̃₁ ∈ ψ̃₁s]...)
end


function unitary_rollout(
    Ũ⃗₁::AbstractVector{<:Real},
    controls::AbstractMatrix{Float64},
    Δt::Union{AbstractVector{Float64}, AbstractMatrix{Float64}, Float64},
    system::QuantumSystem;
    action=Integrators.fourth_order_pade
)
    if Δt isa AbstractMatrix
        @assert size(Δt, 1) == 1
        Δt = vec(Δt)
    elseif Δt isa Float64
        Δt = fill(Δt, size(controls, 2))
    end

    T = size(controls, 2)

    Ũ⃗ = zeros(length(Ũ⃗₁), T)

    Ũ⃗[:, 1] .= Ũ⃗₁

    for t = 2:T
        aₜ₋₁ = controls[:, t - 1]
        Gₜ = Integrators.G(
            aₜ₋₁,
            system.G_drift,
            system.G_drives
        )
        Ũ⃗ₜ₋₁ = Ũ⃗[:, t - 1]
        Ũₜ₋₁ = iso_vec_to_iso_operator(Ũ⃗ₜ₋₁)
        Ũₜ = action(Δt[t - 1], Gₜ, Ũₜ₋₁)
        Ũ⃗ₜ = iso_operator_to_iso_vec(Ũₜ)
        Ũ⃗[:, t] .= Ũ⃗ₜ
    end

    return Ũ⃗
end



function unitary_rollout(
    controls::AbstractMatrix{Float64},
    Δt::Union{AbstractVector{Float64}, AbstractMatrix{Float64}, Float64},
    system::QuantumSystem;
    action=Integrators.fourth_order_pade
)
    return unitary_rollout(
        operator_to_iso_vec(Matrix{ComplexF64}(I(size(system.H_drift_real, 1)))),
        controls,
        Δt,
        system;
        action=action
    )
end

function unitary_rollout(
    traj::NamedTrajectory,
    system::QuantumSystem;
    unitary_name::Symbol=:Ũ⃗,
    drive_name::Symbol=:a,
    action=expv,
    only_drift=false
)
    Ũ⃗₁ = traj.initial[unitary_name]
    if only_drift
        controls = zeros(size(traj[drive_name]))
    else
        controls = traj[drive_name]
    end
    Δt = timesteps(traj)
    return unitary_rollout(
        Ũ⃗₁,
        controls,
        Δt,
        system;
        action=action
    )
end

function QuantumUtils.unitary_fidelity(
    traj::NamedTrajectory,
    system::QuantumSystem;
    unitary_name::Symbol=:Ũ⃗,
    subspace=nothing,
    kwargs...
)
    Ũ⃗_final = unitary_rollout(traj, system; unitary_name=unitary_name, kwargs...)[:, end]
    return unitary_fidelity(
        Ũ⃗_final,
        traj.goal[unitary_name];
        subspace=subspace
    )
end

function QuantumUtils.unitary_fidelity(
    U_goal::AbstractMatrix{ComplexF64},
    controls::AbstractMatrix{Float64},
    Δt::Union{AbstractVector{Float64}, AbstractMatrix{Float64}, Float64},
    system::QuantumSystem;
    subspace=nothing,
    action=expv
)
    Ũ⃗_final = unitary_rollout(controls, Δt, system; action=action)[:, end]
    return unitary_fidelity(
        Ũ⃗_final,
        operator_to_iso_vec(U_goal);
        subspace=subspace
    )
end


function skew_symmetric(v::AbstractVector, n::Int)
    M = zeros(eltype(v), n, n)
    k = 1
    for j = 1:n
        for i = 1:j-1
            vᵢⱼ = v[k]
            M[i, j] = vᵢⱼ
            M[j, i] = -vᵢⱼ
            k += 1
        end
    end
    return M
end

function skew_symmetric_vec(M::AbstractMatrix)
    n = size(M, 1)
    v = zeros(eltype(M), n * (n - 1) ÷ 2)
    k = 1
    for j = 1:n
        for i = 1:j-1
            v[k] = M[i, j]
            k += 1
        end
    end
    return v
end



function unitary_geodesic(
    U_init::AbstractMatrix{<:Number},
    U_goal::AbstractMatrix{<:Number},
    samples::Int;
    return_generator=false
)
    U_init = Matrix{ComplexF64}(U_init)
    U_goal = Matrix{ComplexF64}(U_goal)
    N = size(U_init, 1)
    M = SpecialUnitary(N)
    ts = range(0, 1, length=samples)
    Us = shortest_geodesic(M, U_init, U_goal, ts)
    X = Manifolds.log(M, U_init, U_goal)
    G = iso(X)
    Ũ⃗s = [operator_to_iso_vec(U) for U ∈ Us]
    Ũ⃗ = hcat(Ũ⃗s...)
    G̃⃗ = hcat([skew_symmetric_vec(G) for t = 1:samples]...)
    if return_generator
        return Ũ⃗, G̃⃗
    else
        return Ũ⃗
    end
end

function unitary_geodesic(U_goal, samples; kwargs...)
    N = size(U_goal, 1)
    U_init = Matrix{ComplexF64}(I(N))
    return unitary_geodesic(U_init, U_goal, samples; kwargs...)
end

function linear_interpolation(ψ̃₁::AbstractVector, ψ̃₂::AbstractVector, samples::Int)
    ts = range(0, 1; length=samples)
    ψ̃s = [ψ̃₁ + t * (ψ̃₂ - ψ̃₁) for t ∈ ts]
    return hcat(ψ̃s...)
end

end
