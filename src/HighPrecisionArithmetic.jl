module HighPrecisionArithmetic

  export HIGH_PRECISION_BASE, HighPrecisionInt, @hpi_str

  include("HighPrecisionInteger.jl")   
  include("HighPrecisionLinearAlgebra.jl")

end # module HighPrecisionArithmetic
