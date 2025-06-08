# High Precision Linear Algebra Module

This module extends the functionality of `HighPrecisionArithmetic` by providing basic linear algebra operations for vectors and matrices using `HighPrecisionInt` elements. It enables computations with arbitrary-precision numbers in vector and matrix contexts.

---

## 📦 Dependencies

- **HighPrecisionArithmetic**: Provides the `HighPrecisionInt` type.
- **LinearAlgebra** (Base): Required for defining and overloading operations like `dot`.

---

## 🔧 Type Definitions

### `HighPrecisionVector`

Represents a high-precision vector.

```julia
mutable struct HighPrecisionVector
    elements::Vector{HighPrecisionInt}
end
```

#### Constructors:
- `HighPrecisionVector(elements::Vector{HighPrecisionInt})`: From high-precision elements.
- `HighPrecisionVector(elements::Vector{T}) where {T<:Union{Integer, BigInt}}`: Automatically converts standard integers to `HighPrecisionInt`.

---

### `HighPrecisionMatrix`

Represents a high-precision matrix.

```julia
mutable struct HighPrecisionMatrix
    elements::Vector{Vector{HighPrecisionInt}}
    rows::Int
    cols::Int
end
```

#### Constructors:
- `HighPrecisionMatrix(elements::Vector{Vector{HighPrecisionInt}})`: Validates consistent column lengths.
- `HighPrecisionMatrix(elements::Vector{Vector{T}}) where {T<:Union{Integer, BigInt}}`: Converts integers to `HighPrecisionInt`.

---

## ➕ Operator Overloads and Functions

### Vector Operations

- `Base.:+(v1::HighPrecisionVector, v2::HighPrecisionVector)`
- `Base.:-(v1::HighPrecisionVector, v2::HighPrecisionVector)`
- `Base.:*(scalar::Union{Integer, BigInt, HighPrecisionInt}, v::HighPrecisionVector)`
- `Base.:*(v::HighPrecisionVector, scalar::Union{Integer, BigInt, HighPrecisionInt})`
- `LinearAlgebra.dot(v1::HighPrecisionVector, v2::HighPrecisionVector)`

Note: `dot` uses `BigInt` internally for accumulation, returning a `HighPrecisionInt`.

---

### Matrix Operations

- `Base.:+(m1::HighPrecisionMatrix, m2::HighPrecisionMatrix)`
- `Base.:-(m1::HighPrecisionMatrix, m2::HighPrecisionMatrix)`
- `Base.:*(scalar, m::HighPrecisionMatrix)`
- `Base.:*(m::HighPrecisionMatrix, scalar)`
- `Base.:*(m::HighPrecisionMatrix, v::HighPrecisionVector)`
- `Base.:*(m1::HighPrecisionMatrix, m2::HighPrecisionMatrix)`

Note: Internally uses `BigInt` for intermediate results.

---

### 🖨️ Display Methods

- `Base.show(io::IO, v::HighPrecisionVector)`
- `Base.show(io::IO, m::HighPrecisionMatrix)`

---

## 🧪 Usage Examples

```julia
# Include required modules
include("HighPrecisionArithmetic.jl")
include("HighPrecisionLinearAlgebra.jl")
using .HighPrecisionLinearAlgebra
using .HighPrecisionArithmetic

println("--- HighPrecisionLinearAlgebra Usage Examples ---")

# 1. HighPrecisionVector Creation
vec1 = HighPrecisionVector([1, -2])
vec2 = HighPrecisionVector([1000, -500, 200])
large_vec = HighPrecisionVector([BigInt(2)^70, -BigInt(2)^75, BigInt(2)^80])

# 2. Vector Addition & Subtraction
vec1_compat = HighPrecisionVector([1, 2, 3])
vec2_compat = HighPrecisionVector([10, 20, 30])
v_sum = vec1_compat + vec2_compat
v_diff = vec1_compat - vec2_compat

# 3. Scalar Multiplication
scalar_val = HighPrecisionInt(5)
v_scaled = scalar_val * HighPrecisionVector([1, -2, 3])

# 4. Dot Product
dot_vec_a = HighPrecisionVector([1, 2, 3])
dot_vec_b = HighPrecisionVector([4, 5, 6])
v_dot = LinearAlgebra.dot(dot_vec_a, dot_vec_b)

# 5. Matrix Creation
mat1 = HighPrecisionMatrix([[1, 2], [3, 4]])
mat2 = HighPrecisionMatrix([[5, 6], [7, 8]])
large_mat = HighPrecisionMatrix([[BigInt(2)^60, -BigInt(2)^62], [BigInt(2)^65, BigInt(2)^67]])

# 6. Matrix Addition & Subtraction
m_sum = mat1 + mat2
m_diff = mat1 - mat2

# 7. Matrix Scalar Multiplication
m_scaled = HighPrecisionInt(3) * mat1

# 8. Matrix-Vector Multiplication
m_vec_prod = mat1 * vec1

# 9. Matrix-Matrix Multiplication
m_mat_prod = mat1 * mat2

# Display Results
println("vec1 = $vec1")
println("vec2 = $vec2")
println("large_vec = $large_vec")
println("v_sum = $v_sum")
println("v_diff = $v_diff")
println("v_scaled = $v_scaled")
println("v_dot = $v_dot")
println("mat1 = \n$mat1")
println("mat2 = \n$mat2")
println("large_mat = \n$large_mat")
println("m_sum = \n$m_sum")
println("m_diff = \n$m_diff")
println("m_scaled = \n$m_scaled")
println("m_vec_prod = $m_vec_prod")
println("m_mat_prod = \n$m_mat_prod")

println("\n--- End of Examples ---")
```