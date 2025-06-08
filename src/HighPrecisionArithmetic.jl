module HighPrecisionArithmetic
   include("HighPrecisionNumber.jl") # Defines module HighPrecisionNumber   
   using .HighPrecisionNumber

   include("HighPrecisionLinearAlgebra.jl") # Defines module HighPrecisionLinearAlgebra
   using .HighPrecisionLinearAlgebra

   export HighPrecisionNumber, HighPrecisionLinearAlgebra 

end # module HighPrecisionArithmetic