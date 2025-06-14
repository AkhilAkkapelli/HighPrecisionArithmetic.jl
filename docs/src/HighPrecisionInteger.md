```@meta
DocTestSetup = quote
    using HighPrecisionArithmetic
    
end
```

# 🔢 High Precision Number

This module introduces `HighPrecisionInt`, a custom type for arbitrary-precision integer arithmetic, exceeding standard limits like `Int64` or `UInt128`.


## 📘 Definitions

### HIGH_PRECISION_BASE 

```julia
const HIGH_PRECISION_BASE = UInt64(2)^32
```

Defines the base ``B = 2^{32}`` used for arithmetic, where each `UInt64` coefficient holds a 32-bit "digit", leaving  the upper 32 bits for intermediate calculations without overflow before normalization. 

### HighPrecisionInt 

The core of the module is the `HighPrecisionInt` struct. It represents numbers as a vector of `coeffs::Vector{UInt64}` coefficients, effectively "digits" in base `HIGH_PRECISION_BASE`, along with a `sign::Int8` sign.

```julia
mutable struct HighPrecisionInt
    coeffs::Vector{UInt64} # Coefficients in little-endian order
    sign::Int8              # 1 (positive), -1 (negative), 0 (zero)
end
```

Mathematically, a `HighPrecisionInt` ``N`` is represented as:

``N = \text{sign} \times \sum_{i=1}^{\text{length(coeffs)}} \text{coeffs}[i] \cdot B^{i-1}``

where ``B`` is the `HIGH_PRECISION_BASE`, with coefficients `coeffs` stored in little-endian order.

## ➕ Key Functions and Operators

### 🧱 Constructors

You can create a `HighPrecisionInt` in several ways:

- **From coefficients and sign:** 
  
  `HighPrecisionInt(coeffs::Vector{UInt64}, sign::Int8=1)`  
  
  Creates a `HighPrecisionInt` using a coefficient vector and optional sign, applying `normalize!` to maintain canonical form.

  **Usage**

  ```jldoctest
  julia> hpi_basic = HighPrecisionInt([UInt64(123)])
  HighPrecisionInt(123, coeffs=[123])

  julia> hpi_zero = HighPrecisionInt([UInt64(0)])
  HighPrecisionInt(0, coeffs=[])

  julia> hpi_negative = HighPrecisionInt([UInt64(100)], Int8(-1))
  HighPrecisionInt(-100, coeffs=[100])

  julia> hpi_large = HighPrecisionInt([UInt64(1), UInt64(5), UInt64(1)])
  HighPrecisionInt(21474836481, coeffs=[1, 5, 1])
  ```

- **From Julia `Integer` or `BigInt`:**
  
  `HighPrecisionInt(x::T) where {T<:Union{Integer, BigInt}}`

  Converts a Julia `Integer` or `BigInt` into a `HighPrecisionInt`, the primary and most convenient method for creating high-precision numbers from built-in types.

  ```jldoctest
  julia> hpi_int = HighPrecisionInt(123)
  HighPrecisionInt(123, coeffs=[123])

  julia> hpi_neg_int = HighPrecisionInt(-4567)
  HighPrecisionInt(-4567, coeffs=[4567])

  julia> hpi_zero_int = HighPrecisionInt(0)
  HighPrecisionInt(0, coeffs=[])

  julia> val_big = HighPrecisionInt(BigInt(2)^76 - 1)
  HighPrecisionInt(18446744073709551615, coeffs=[4294967295, 4294967295, 4095])

  julia> val_big_neg = HighPrecisionInt(-BigInt(2)^92 - 1)
  HighPrecisionInt(-1, coeffs=[1, 0, 268435456])
  ```

### 🛠️ Internal Utilities

- `normalize!(hpi::HighPrecisionInt)`
  
  Ensures canonical form by handling carries (``0 \le c_i < B``), removing leading zeros, and setting the correct sign (especially for zero). This function is called automatically by the `HighPrecisionInt` constructors and other operations to maintain canonical form.

### 🔁 Conversions

- `Base.BigInt(hpi::HighPrecisionInt)`
  
  Converts `hpi::HighPrecisionInt` value to a `bi::BigInt` using 
  
  ``\text{bi} = \text{hpi.sign} \times \sum \text{hpi.coeff}_i \cdot B^{i-1}``

   useful for verification or interoperability with libraries that use `BigInt`.

  **Usage**

  ```jldoctest
  julia> hpi_val = HighPrecisionInt(12345678901234567890)
  HighPrecisionInt(12345678901234567890, coeffs=[3944680146, 2874452364])

  julia> bi_val = BigInt(hpi_val)
  12345678901234567890

  julia> hpi_neg = HighPrecisionInt(-BigInt(2)^70)
  HighPrecisionInt(0, coeffs=[0, 0, 64])

  julia> bi_neg = BigInt(hpi_neg)
  0

  julia> hpi_zero = HighPrecisionInt(0)
  HighPrecisionInt(0, coeffs=[])

  julia> bi_zero = BigInt(hpi_zero)
  0
  ```

### 🔄 Unary Operations

- `Base.abs(hpi::HighPrecisionInt)`:  
  Returns the absolute value of a `HighPrecisionInt`.

  **Usage**

  ```jldoctest
  julia> abs(HighPrecisionInt(123))
  HighPrecisionInt(123, coeffs=[123])

  julia> abs(HighPrecisionInt(-456))
  HighPrecisionInt(456, coeffs=[456])

  julia> abs(HighPrecisionInt(0))
  HighPrecisionInt(0, coeffs=[])
  ```

- `Base.:-(hpi::HighPrecisionInt)`:  
  Unary negation; flips `hpi.sign`.

  **Usage**

  ```jldoctest
  julia> -HighPrecisionInt(100)
  HighPrecisionInt(-100, coeffs=[100])

  julia> -HighPrecisionInt(-200)
  HighPrecisionInt(200, coeffs=[200])

  julia> -HighPrecisionInt(0)
  HighPrecisionInt(0, coeffs=[])
  ```

### ⚖️ Comparison Operators

- `Base.isequal(a::HighPrecisionInt, b::HighPrecisionInt)`
    
  Checks if two `HighPrecisionInt` instances are equal. Also aliased by `Base.:(==)`.

  **Usage**

  ```jldoctest
  julia> HighPrecisionInt(10) == HighPrecisionInt(10)
  true

  julia> HighPrecisionInt(10) == HighPrecisionInt(20)
  false

  julia> HighPrecisionInt(0) == HighPrecisionInt(-0)
  true

  julia> HighPrecisionInt(BigInt(2)^54 + 2) == HighPrecisionInt(2^53 + 2^53 + 2)
  true

  julia> HighPrecisionInt(BigInt(2)^154 + 2) == HighPrecisionInt(4*BigInt(2)^151 + BigInt(2)^153 + 2)
  true

  julia> HighPrecisionInt(BigInt(1000000000000)) == HighPrecisionInt(1000000000000)
  true
  ```

- `Base.isless(a::HighPrecisionInt, b::HighPrecisionInt)`
   
  Checks if `a` is strictly less than `b`. Also aliased by `Base.:(<)`.

  **Usage**

  ```jldoctest
  julia> HighPrecisionInt(5) < HighPrecisionInt(10)
  true

  julia> HighPrecisionInt(10) < HighPrecisionInt(-5)
  false

  julia> HighPrecisionInt(0) < HighPrecisionInt(0)
  false

  julia> HighPrecisionInt(BigInt(2)^73) < HighPrecisionInt(-10)
  false

  julia> HighPrecisionInt(BigInt(2)^112) < HighPrecisionInt(BigInt(2)^111)
  false
  ```

### 🧮 Arithmetic Operators

All arithmetic operations correctly handle signs and normalize results.

- **Addition:**
 
  `Base.:+(a::HighPrecisionInt, b::HighPrecisionInt)`

   Adds ``a`` and ``b``. 
   
   If signs are the same, magnitudes are added with carry. If signs differ, it computes ``\pm (||a| - |b||)`` using `abs_subtract`.

  **Usage**

  ```jldoctest
  julia> HighPrecisionInt(1000) + HighPrecisionInt(2000)
  HighPrecisionInt(3000, coeffs=[3000])

  julia> HighPrecisionInt(-1000) + HighPrecisionInt(-2000)
  HighPrecisionInt(-3000, coeffs=[3000])

  julia> hpi_large = HighPrecisionInt(BigInt(98765432109876543210987654321098765))
  HighPrecisionInt(-3000, coeffs=[3000])

  julia> hpi_small = HighPrecisionInt(-12345)
  HighPrecisionInt(-3000, coeffs=[3000])

  julia> hpi_large + hpi_small
  HighPrecisionInt(98765432109876543210987654320986420, coeffs=[3102421704, 2874136453, 2874136453, 2874136453, 2874136453, 229])

  julia> hpi_small = HighPrecisionInt(12345)
  HighPrecisionInt(-3000, coeffs=[3000])

  julia> hpi_large = HighPrecisionInt(BigInt(98765432109876543210987654321098765))
  HighPrecisionInt(-3000, coeffs=[3000])

  julia> hpi_small + hpi_large 
  HighPrecisionInt(98765432109876543210987654321101009, coeffs=[3102446385, 2874136453, 2874136453, 2874136453, 2874136453, 229])

  julia> HighPrecisionInt(BigInt(2)^34+1) + HighPrecisionInt(-3*BigInt(2)^31+1)
  HighPrecisionInt(0, coeffs=[])

  julia> HighPrecisionInt(123) + HighPrecisionInt(0)
  HighPrecisionInt(123, coeffs=[123])
  ```
