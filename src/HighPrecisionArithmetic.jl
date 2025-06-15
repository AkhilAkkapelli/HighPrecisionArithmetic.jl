module HighPrecisionArithmetic

  export HIGH_PRECISION_BASE, HighPrecisionInt, @hpi_str
  export HighPrecisionVector, HighPrecisionMatrix

  include("HighPrecisionInteger.jl")   
  include("HighPrecisionLinearAlgebra.jl")

end # module HighPrecisionArithmetic
