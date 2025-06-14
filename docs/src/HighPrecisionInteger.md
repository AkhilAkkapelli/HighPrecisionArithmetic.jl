```@meta
CurrentModule = HighPrecisionArithmetic
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

  ```jldoctest; output = false
  julia> hpi_basic = HighPrecisionInt([UInt64(123)])
  HighPrecisionInt(123, coeffs=[123])

  julia> hpi_zero = HighPrecisionInt([UInt64(0)])
  HighPrecisionInt(0, coeffs=[])

  julia> hpi_negative = HighPrecisionInt([UInt64(100)], Int8(-1))
  HighPrecisionInt(-100, coeffs=[100])

  julia> hpi_large = HighPrecisionInt([UInt64(1), UInt64(5), UInt64(1)])
  HighPrecisionInt(4294967300, coeffs=[1, 5, 1])
  ```

- **From Julia `Integer` or `BigInt`:**
  
  `HighPrecisionInt(x::T) where {T<:Union{Integer, BigInt}}`

  Converts a Julia `Integer` or `BigInt` into a `HighPrecisionInt`, the primary and most convenient method for creating high-precision numbers from built-in types.

  ```jldoctest; output = false
  julia> hpi_int = HighPrecisionInt(123)
  HighPrecisionInt(123, coeffs=[123])

  julia> hpi_neg_int = HighPrecisionInt(-4567)
  HighPrecisionInt(-4567, coeffs=[4567])

  julia> hpi_zero_int = HighPrecisionInt(0)
  HighPrecisionInt(0, coeffs=[])

  julia> val_big = HighPrecisionInt(BigInt(2)^76 - 1)
  HighPrecisionInt(75557863725914323419137578995328896009, coeffs=[4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 255])

  julia> val_big_neg = HighPrecisionInt(-BigInt(2)^92 - 1)
  HighPrecisionInt(-4951760157141521099596496896196859873, coeffs=[4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 255])
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

  ```jldoctest; output = false
  julia> hpi_val = HighPrecisionInt(12345678901234567890)
  HighPrecisionInt(12345678901234567890, coeffs=[124989312, 2874136453])

  julia> bi_val = BigInt(hpi_val)
  12345678901234567890

  julia> hpi_neg = HighPrecisionInt(-BigInt(2)^70)
  HighPrecisionInt(-1180591620717411303424, coeffs=[0, 0, 0, 0, 0, 4])

  julia> bi_neg = BigInt(hpi_neg)
  -1180591620717411303424

  julia> hpi_zero = HighPrecisionInt(0)
  HighPrecisionInt(0, coeffs=[])

  julia> bi_zero = BigInt(hpi_zero)
  0
  ```

### 🔄 Unary Operations

- `Base.abs(hpi::HighPrecisionInt)`:  
  Returns the absolute value of a `HighPrecisionInt`.

  **Usage**

  ```jldoctest; output = false
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

  ```jldoctest; output = false
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

  ```jldoctest; output = false
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

  julia> HighPrecisionInt(BigInt("1000000000000")) == HighPrecisionInt(1000000000000)
  true
  ```

- `Base.isless(a::HighPrecisionInt, b::HighPrecisionInt)`
   
  Checks if `a` is strictly less than `b`. Also aliased by `Base.:(<)`.

  **Usage**

  ```jldoctest; output = false
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

  ```jldoctest; output = false
  julia> HighPrecisionInt(1000) + HighPrecisionInt(2000)
  HighPrecisionInt(3000, coeffs=[3000])

  julia> HighPrecisionInt(-1000) + HighPrecisionInt(-2000)
  HighPrecisionInt(-3000, coeffs=[3000])

  julia> hpi_large = HighPrecisionInt(BigInt(98765432109876543210987654321098765))

  julia> hpi_small = HighPrecisionInt(-12345)

  julia> hpi_large + hpi_small
  HighPrecisionInt(98765432109876543210987654320986420, coeffs=[3102421704, 2874136453, 2874136453, 2874136453, 2874136453, 229])

  julia> hpi_small = HighPrecisionInt(12345)

  julia> hpi_large = HighPrecisionInt(BigInt(98765432109876543210987654321098765))

  julia> hpi_small + hpi_large 
  HighPrecisionInt(98765432109876543210987654321101009, coeffs=[3102446385, 2874136453, 2874136453, 2874136453, 2874136453, 229])

  julia> HighPrecisionInt(BigInt(2)^34+1) + HighPrecisionInt(-3*BigInt(2)^31+1)
  HighPrecisionInt(0, coeffs=[])

  julia> HighPrecisionInt(123) + HighPrecisionInt(0)
  HighPrecisionInt(123, coeffs=[123])
  ```

- **Subtract:**
  
   `Base.:-(a::HighPrecisionInt, b::HighPrecisionInt)` 

  Subtracts ``b`` from ``a``; implemented as ``a + (-b)``.

  **Usage**

  ```jldoctest; output = false
  julia> HighPrecisionInt(1000) - HighPrecisionInt(2000)
  HighPrecisionInt(-1000, coeffs=[1000])

  julia> HighPrecisionInt(-1000) - HighPrecisionInt(-2000)
  HighPrecisionInt(1000, coeffs=[1000])

  julia> hpi_large = HighPrecisionInt(BigInt(98765432109876543210987654321098765))

  julia> hpi_small = HighPrecisionInt(12345)

  julia> hpi_large - hpi_small
  HighPrecisionInt(98765432109876543210987654320986420, coeffs=[3102421704, 2874136453, 2874136453, 2874136453, 2874136453, 229])

  julia> hpi_small = HighPrecisionInt(12345)

  julia> hpi_large = HighPrecisionInt(BigInt(98765432109876543210987654321098765))

  julia> hpi_small - hpi_large
  HighPrecisionInt(-98765432109876543210987654320986420, coeffs=[3102421704, 2874136453, 2874136453, 2874136453, 2874136453, 229])

  julia> HighPrecisionInt(BigInt(2)^34+1) - HighPrecisionInt(3*BigInt(2)^31+1)
  HighPrecisionInt(0, coeffs=[])

  julia> HighPrecisionInt(123) - HighPrecisionInt(0)
  HighPrecisionInt(123, coeffs=[123])
  ```  

- **Multiplication:**
  
  `Base.:*(a::HighPrecisionInt, b::HighPrecisionInt)`  

  Multiplies ``a`` and ``b`` using long multiplication in base ``B``. Partial products ``a_i \cdot b_j`` are accumulated with carry propagation.

  ```math
  a \cdot b = \sum_{k=1}^{\text{len_a}} \sum_{l=1}^{\text{len_b}} (a_k \cdot b_l) \cdot B^{k+l-2}
  ```

  **Usage**

  ```jldoctest; output = false
  julia> HighPrecisionInt(15) * HighPrecisionInt(8)
  HighPrecisionInt(120, coeffs=[120])

  julia> HighPrecisionInt(15) * HighPrecisionInt(-8)
  HighPrecisionInt(-120, coeffs=[120])

  julia> HighPrecisionInt(123) * HighPrecisionInt(0)
  HighPrecisionInt(0, coeffs=[])

  julia> hpi_large_1 = HighPrecisionInt(BigInt(123456789012345))
  HighPrecisionInt(123456789012345, coeffs=[3102434049, 2874136453, 28])

  julia> hpi_large_2 = HighPrecisionInt(BigInt(987654321098765))
  HighPrecisionInt(987654321098765, coeffs=[2705663685, 2290649241, 229])

  julia> hpi_large_1 * hpi_large_2
  HighPrecisionInt(1219326311370217961298565538965, coeffs=[3071378145, 1699929532, 2908879550, 48261358, 2800455799, 1378418047, 6596])

  julia> hpi_large_3 = HighPrecisionInt(BigInt(12345678901234567890123))
  HighPrecisionInt(12345678901234567890123, coeffs=[3102434049, 2874136453, 2874136453, 2874136453, 2874136453, 28])

  julia> hpi_large_4 = HighPrecisionInt(-BigInt(98765432109876543210987))
  HighPrecisionInt(-98765432109876543210987, coeffs=[2705663685, 2290649241, 2290649241, 2290649241, 2290649241, 229])

  julia> hpi_large_3 * hpi_large_4
  HighPrecisionInt(-1219326311370217961298565538965809804868953041, coeffs=[891632035, 3355018698, 2284949540, 114421111, 2244249110, 1261386766, 1261386766, 1261386766, 1261386766, 1261386766, 1261386766, 1261386766, 1261386766, 2818987453, 1261386766, 1261386766, 1261386766, 1261386766, 2818987453, 1261386766, 1261386766, 1261386766, 2818987453, 1261386766, 1261386766, 2818987453, 28])
  ```

### 🧩 Macros

  `@hpi_str(s::String)`

- Constructs a `HighPrecisionInt` from a string literal `s` (decimal or "0x" prefixed hex).

  **Usage**

  ```jldoctest; output = false
  julia> hpi"12345678901234567890"
  HighPrecisionInt(12345678901234567890, coeffs=[124989312, 2874136453])

  julia> hpi"-0xABCDEF"
  HighPrecisionInt(-11259375, coeffs=[11259375])

  julia> hpi"1234567890123456789012345678901234567890"
  HighPrecisionInt(1234567890123456789012345678901234567890, coeffs=[3770425858, 1073741824, 2874136453, 3131706624, 2874136453, 28])
  ```

### 🖥️ Display

  `Base.show(io::IO, hpi::HighPrecisionInt)`

  Defines how `HighPrecisionInt` are displayed when printed, showing their equivalent decimal value and coefficients in little-endian order. 

  **Usage**

  ```jldoctest; output = false
  julia> hpi_1 = HighPrecisionInt(99999999999999999999)
  HighPrecisionInt(99999999999999999999, coeffs=[1775798783, 1260799867, 23])

  julia> hpi_2 = HighPrecisionInt(-1234567890)
  HighPrecisionInt(-1234567890, coeffs=[1234567890])

  julia> hpi_3 = HighPrecisionInt(0)
  HighPrecisionInt(0, coeffs=[0])
  ```

## 🧪 Verification Examples

To ensure the correctness of the `HighPrecisionInt` , the following examples demonstrate various operations and verify their results against Julia's built-in `BigInt` type.

```julia
using HighPrecisionArithmetic

# 1. Creation and Conversion Verification
BigInt(HighPrecisionInt(typemax(UInt128))) == typemax(UInt128)
BigInt(HighPrecisionInt(-BigInt(2)^150 - 1)) == (-BigInt(2)^150 - 1)

# 2. Addition Verification
BigInt(HighPrecisionInt(1000) + HighPrecisionInt(2000)) == 3000
BigInt(HighPrecisionInt(-1000) + HighPrecisionInt(-2000)) == -3000
expected_sum_diff_signs_pos = BigInt(98765432109876543210987654321098765) - BigInt(12345)
BigInt(HighPrecisionInt(BigInt(98765432109876543210987654321098765)) + HighPrecisionInt(-BigInt(12345))) == expected_sum_diff_signs_pos
expected_sum_diff_signs_neg = BigInt(12345) - BigInt(98765432109876543210987654321098765)
BigInt(HighPrecisionInt(BigInt(12345)) + HighPrecisionInt(-BigInt(98765432109876543210987654321098765))) == expected_sum_diff_signs_neg

# 3. Subtraction Verification
BigInt(HighPrecisionInt(5000) - HighPrecisionInt(2000)) == 3000
BigInt(HighPrecisionInt(2000) - HighPrecisionInt(5000)) == -3000

# 4. Multiplication Verification
BigInt(HighPrecisionInt(15) * HighPrecisionInt(8)) == 120
BigInt(HighPrecisionInt(-15) * HighPrecisionInt(8)) == -120
expected_product_large_signed = BigInt(12345678901234567890123) * -BigInt(98765432109876543210987)
BigInt(HighPrecisionInt(BigInt(12345678901234567890123)) * HighPrecisionInt(-BigInt(98765432109876543210987))) == expected_product_large_signed
```
