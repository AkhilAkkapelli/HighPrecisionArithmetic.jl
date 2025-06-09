using Pkg
using Test

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()

@testset "HighPrecision Library Tests" begin
  
    include("TestHighPrecisionNumber.jl")
    include("TestHighPrecisionLinearAlgebra.jl")
  
end
