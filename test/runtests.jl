using Test

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

@testset "HighPrecisionArithmetic Library Tests" begin
  
    #include("TestHighPrecisionNumber.jl")
    #include("TestHighPrecisionLinearAlgebra.jl")
  
end
