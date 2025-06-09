<div class="flex items-center justify-center w-full p-4">
    <div class="flex flex-col sm:flex-row items-center sm:items-center w-full max-w-4xl space-y-4 sm:space-y-0 sm:space-x-8">
        <a href="https://akhilakkapelli.github.io/HighPrecisionArithmetic.jl" class="flex-shrink-0">
            <img src="https://raw.githubusercontent.com/AkhilAkkapelli/HighPrecisionArithmetic.jl/master/docs/src/assets/logo.svg"
                 alt="High Precision Arithmetic Docs Logo"
                 class="w-28 h-auto sm:w-36 rounded-lg shadow-md"
                 onerror="this.onerror=null;this.src='https://placehold.co/120x120/e2e8f0/334155?text=Logo';" />
        </a>
        <div class="flex-grow text-center sm:text-left">
            <h2 class="text-lg sm:text-xl md:text-2xl font-bold text-gray-800 leading-tight">
                Julia-based library for precise linear algebra using high-precision arithmetic
            </h2>
        </div>
    </div>
</div>

# High Precision Arithmetic in Julia

This Julia library provides custom types and operations for performing high-precision arithmetic and linear algebra. It's designed for scenarios where standard floating-point or fixed-size integer types might not offer sufficient precision for very large numbers or complex computations.

## Features

This library is composed of two main modules:

1. `HighPrecisionArithmetic`
   - **Arbitrary Precision Integers**: Defines `HighPrecisionInt` to handle integers of virtually any size, limited only by available memory.
   - **Core Arithmetic Operations**: Overloads standard arithmetic operators (`+`, `-`, `*`) for `HighPrecisionInt` objects, ensuring precision is maintained across operations.
   - **Conversions**: Seamlessly convert between Julia's `BigInt` and `HighPrecisionInt`.
2. `HighPrecisionLinearAlgebra`
   - **High Precision Vectors**: Introduces HighPrecisionVector for vectors whose elements are HighPrecisionInts.
   - **High Precision Matrices**: Introduces `HighPrecisionMatrix` for matrices composed of `HighPrecisionInt` elements.
   - **Vector Operations**: Supports vector addition (`+`), subtraction (`-`), scalar multiplication (`*`), and dot product (`LinearAlgebra.dot`).
   - **Matrix Operations**: Supports matrix addition (`+`), subtraction (`-`), scalar multiplication (`*`), matrix-vector multiplication (`*`), and matrix-matrix multiplication (`*`).
   - **Optimized Inner Loops**: For performance-critical matrix and vector multiplications, intermediate products and sums are computed using Julia's native `BigInt` for efficiency, then converted back to `HighPrecisionInt` for the final result.
  
  ## Getting Started
  
  To use this library, you'll need to have Julia installed.
  
  ### Installation
  
  Since this is a local library (not a registered package), you'll need to place the module files directly into your project directory or a location Julia can access.
  
  1. Save the code for the `HighPrecisionArithmetic` module into a file named `HighPrecisionArithmetic.jl`.
  
  2. Save the code for the `HighPrecisionLinearAlgebra` module into a file named `HighPrecisionLinearAlgebra.jl` in the same directory as `HighPrecisionArithmetic.jl`. 

### Usage
    
You can load and use the modules in your Julia script or REPL:

```julia
# 1. Include the HighPrecisionArithmetic module
include("HighPrecisionArithmetic.jl")

# 2. Include and use the HighPrecisionLinearAlgebra module
#    (which also brings HighPrecisionArithmetic into scope implicitly for its types)
include("HighPrecisionLinearAlgebra.jl")
using .HighPrecisionLinearAlgebra
using .HighPrecisionArithmetic # Optional: use if you directly instantiate HighPrecisionInt often
```

## Examples

Here are some quick examples to get you started:

### High Precision Integers

```julia
using .HighPrecisionArithmetic

# Create HighPrecisionInt
a = HighPrecisionInt(12345678901234567890)
b = HighPrecisionInt(9876543210987654321)

# Addition
sum_val = a + b
println("Sum: $sum_val")

# Multiplication
prod_val = a * b
println("Product: $prod_val")

# Convert to BigInt for verification
println("Sum as BigInt: $(BigInt(sum_val))")
```

### High Precision Vectors and Matrices

```julia
using .HighPrecisionLinearAlgebra
using .HighPrecisionArithmetic # Ensure HighPrecisionInt is directly accessible

# Create HighPrecisionVectors
vec_a = HighPrecisionVector([10, -20, 30])
vec_b = HighPrecisionVector([5, 15, -25])

# Vector Addition
vec_sum = vec_a + vec_b
println("\nVector Sum: $vec_sum")

# Dot Product (leveraging BigInt for intermediate precision)
dot_prod = LinearAlgebra.dot(vec_a, vec_b)
println("Dot Product: $dot_prod")

# Create HighPrecisionMatrices
mat1 = HighPrecisionMatrix([[1, 2], [3, 4]])
mat2 = HighPrecisionMatrix([[5, 6], [7, 8]])

# Matrix Multiplication (leveraging BigInt for intermediate precision)
mat_prod = mat1 * mat2
println("\nMatrix Product:\n$mat_prod")

# Matrix-Vector Multiplication (compatible dimensions)
vec_c = HighPrecisionVector([HighPrecisionInt(1), HighPrecisionInt(2)]) # Needs to match mat1 columns
mat_vec_prod = mat1 * vec_c
println("\nMatrix-Vector Product:\n$mat_vec_prod")
```

## Structure

The library is organized into two primary Julia modules:

- `HighPrecisionArithmetic.jl`: Contains the fundamental `HighPrecisionInt` type and its core arithmetic operations (`+`, `-`, `*`, `abs`, comparisons). This forms the base for all high-precision numerical work.

- `HighPrecisionLinearAlgebra.jl`: Builds upon `HighPrecisionArithmetic`. It defines `HighPrecisionVector` and `HighPrecisionMatrix` and overloads linear algebra operations (addition, subtraction, scalar multiplication, dot product, matrix-vector, and matrix-matrix multiplication) to work with these high-precision types. It intelligently uses `BigInt` internally for efficient accumulation during multiplications to maintain full precision.
  
## License

This project is made available under the terms of the MIT license.
