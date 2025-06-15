```@meta
DocTestSetup = quote
    using HighPrecisionArithmetic 
end
```

# 🔢 High Precision Number

This module introduces [`HighPrecisionInt`](@ref), a custom type for arbitrary-precision integer arithmetic, exceeding standard limits like `Int64` or `UInt128`.


  ## 📘 Definitions

  ### HIGH PRECISION BASE 

  ```julia
  const HIGH_PRECISION_BASE = UInt64(2)^32
  ```

  Defines the `HIGH_PRECISION_BASE`  ``B = 2^{32}`` used for arithmetic, where each `UInt64` coefficient holds a 32-bit "digit", leaving  the upper 32 bits for intermediate calculations without overflow before normalization. 

  ### High Precision Int 

  The core of the module is the [`HighPrecisionInt`](@ref) struct. It represents numbers as a vector of `coeffs::Vector{UInt64}` coefficients, effectively "digits" in base `HIGH_PRECISION_BASE`, along with a `sign::Int8` sign.

  ```julia
  mutable struct HighPrecisionInt
      coeffs::Vector{UInt64} # Coefficients in little-endian order
      sign::Int8              # 1 (positive), -1 (negative), 0 (zero)
  end
  ```

  Mathematically, a [`HighPrecisionInt`](@ref) is represented as:

  ``\text{HPI} = \text{sign} \times \sum_{i=1}^{\text{length(coeffs)}} \text{coeffs}[i] \cdot B^{i-1}``

  where ``B`` is the `HIGH_PRECISION_BASE`, with coefficients `coeffs` stored in little-endian order.

  ## ➕ Key Functions and Operators

  ### 🧱 Constructors

  You can create a [`HighPrecisionInt`](@ref) in several ways:

  - **From coefficients and sign:** 
    
    `HighPrecisionInt(coeffs::Vector{UInt64}, sign::Int8=1)`  
    
    Creates a [`HighPrecisionInt`](@ref) using a coefficient vector and optional sign, applying `normalize!` to maintain canonical form.

    **Usage**

    ```jldoctest
    julia> hpi_basic = HighPrecisionInt([UInt64(123)])
    HighPrecisionInt(123, coeffs=[123])

    julia> hpi_zero = HighPrecisionInt([UInt64(0)])
    HighPrecisionInt(0, coeffs=[])

    julia> hpi_negative = HighPrecisionInt([UInt64(100)], Int8(-1))
    HighPrecisionInt(-100, coeffs=[100])

    julia> hpi_large = HighPrecisionInt([UInt64(1), UInt64(5), UInt64(1)])
    HighPrecisionInt(18446744095184388097, coeffs=[1, 5, 1])
    ```
  - **From Julia `Integer` or `BigInt`:**
    
    `HighPrecisionInt(x::T) where {T<:Union{Integer, BigInt}}`

    Converts a Julia `Integer` or `BigInt` into a [`HighPrecisionInt`](@ref), the primary and most convenient method for creating high-precision numbers from built-in types.

    **Usage**
    ```jldoctest
    julia> hpi_int = HighPrecisionInt(123)
    HighPrecisionInt(123, coeffs=[123])

    julia> hpi_neg_int = HighPrecisionInt(-4567)
    HighPrecisionInt(-4567, coeffs=[4567])

    julia> hpi_zero_int = HighPrecisionInt(0)
    HighPrecisionInt(0, coeffs=[])

    julia> val_big = HighPrecisionInt(BigInt(2)^76 - 1)
    HighPrecisionInt(75557863725914323419135, coeffs=[4294967295, 4294967295, 4095])

    julia> val_big_neg = HighPrecisionInt(-BigInt(2)^92 - 1)
    HighPrecisionInt(-4951760157141521099596496897, coeffs=[1, 0, 268435456])
    ```
  ### 🛠️ Internal Utilities

  - **Normalize:** `normalize!(hpi::HighPrecisionInt)`
    
    Ensures canonical form by handling carries (``0 \le c_i < B``), removing leading zeros, and setting the correct sign (especially for zero). This function is called automatically by the [`HighPrecisionInt`](@ref) constructors and other operations to maintain canonical form.

  ### 🔁 Conversions

  - **`HighPrecisionInt` to `BigInt`:** `Base.BigInt(hpi::HighPrecisionInt)`
    
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
    HighPrecisionInt(-1180591620717411303424, coeffs=[0, 0, 64])

    julia> bi_neg = BigInt(hpi_neg)
    -1180591620717411303424

    julia> hpi_zero = HighPrecisionInt(0)
    HighPrecisionInt(0, coeffs=[])

    julia> bi_zero = BigInt(hpi_zero)
    0
    ```
  ### 🪞 Unary Operations

  - **Absolute:** `Base.abs(hpi::HighPrecisionInt)`:  
    Returns the absolute value of a [`HighPrecisionInt`](@ref).

    **Usage**

    ```jldoctest
    julia> abs(HighPrecisionInt(123))
    HighPrecisionInt(123, coeffs=[123])

    julia> abs(HighPrecisionInt(-456))
    HighPrecisionInt(456, coeffs=[456])

    julia> abs(HighPrecisionInt(0))
    HighPrecisionInt(0, coeffs=[])
    ```
  - **Negation:** `Base.:-(hpi::HighPrecisionInt)`:  
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

  - **IsEqual:** `Base.isequal(a::HighPrecisionInt, b::HighPrecisionInt)`
      
    Checks if two [`HighPrecisionInt`](@ref) instances are equal. Also aliased by `Base.:(==)`.

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
  - **IsLess:** `Base.isless(a::HighPrecisionInt, b::HighPrecisionInt)`
    
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

  - **Addition:** `Base.:+(a::HighPrecisionInt, b::HighPrecisionInt)`

    Adds ``a`` and ``b``. 
    
    If signs are the same, magnitudes are added with carry. If signs differ, it computes ``\pm (||a| - |b||)`` using `abs_subtract`.

    **Usage**
    ```jldoctest 
    julia> HighPrecisionInt(1000) + HighPrecisionInt(2000)
    HighPrecisionInt(3000, coeffs=[3000])

    julia> HighPrecisionInt(-1000) + HighPrecisionInt(-2000)
    HighPrecisionInt(-3000, coeffs=[3000])

    julia> hpi_large = HighPrecisionInt(BigInt(98765432109876543210987654321098765))
    HighPrecisionInt(98765432109876543210987654321098765, coeffs=[2171162637, 1292186391, 46642767, 1246595])

    julia> hpi_small = HighPrecisionInt(-12345)
    HighPrecisionInt(-12345, coeffs=[12345])

    julia> hpi_large + hpi_small
    HighPrecisionInt(98765432109876543210987654321086420, coeffs=[2171150292, 1292186391, 46642767, 1246595])

    julia> hpi_small = HighPrecisionInt(12345)
    HighPrecisionInt(12345, coeffs=[12345])
    
    julia> hpi_small + hpi_large 
    HighPrecisionInt(98765432109876543210987654321111110, coeffs=[2171174982, 1292186391, 46642767, 1246595])
    
    julia> HighPrecisionInt(BigInt(2)^34+1) + HighPrecisionInt(-8*BigInt(2)^31-1)
    HighPrecisionInt(0, coeffs=[])
    
    julia> HighPrecisionInt(123) + HighPrecisionInt(0)
    HighPrecisionInt(123, coeffs=[123]) 
    ```  
  - **Subtraction:** `Base.:-(a::HighPrecisionInt, b::HighPrecisionInt)` 

    Subtracts ``b`` from ``a``; implemented as ``a + (-b)``.

    **Usage**
    ```jldoctest
    julia> HighPrecisionInt(1000) - HighPrecisionInt(2000)
    HighPrecisionInt(-1000, coeffs=[1000])

    julia> HighPrecisionInt(-1000) - HighPrecisionInt(-2000)
    HighPrecisionInt(1000, coeffs=[1000])

    julia> hpi_large = HighPrecisionInt(BigInt(98765432109876543210987654321098765))
    HighPrecisionInt(98765432109876543210987654321098765, coeffs=[2171162637, 1292186391, 46642767, 1246595])

    julia> hpi_small = HighPrecisionInt(12345)
    HighPrecisionInt(12345, coeffs=[12345])

    julia> hpi_large - hpi_small
    HighPrecisionInt(98765432109876543210987654321086420, coeffs=[2171150292, 1292186391, 46642767, 1246595])

    julia> hpi_small - hpi_large
    HighPrecisionInt(-98765432109876543210987654321086420, coeffs=[2171150292, 1292186391, 46642767, 1246595])

    julia> HighPrecisionInt(BigInt(2)^34+1) - HighPrecisionInt(3*BigInt(2)^31+1)
    HighPrecisionInt(10737418240, coeffs=[2147483648, 2])

    julia> HighPrecisionInt(123) - HighPrecisionInt(0)
    HighPrecisionInt(123, coeffs=[123])
    ```  
  - **Multiplication:** `Base.:*(a::HighPrecisionInt, b::HighPrecisionInt)`  

    Multiplies ``a`` and ``b`` using long multiplication in base ``B``. Partial products ``a_i \cdot b_j`` are accumulated with carry propagation.

    ``a \cdot b = \sum_{k=1}^{\text{len\_a}} \sum_{l=1}^{\text{len\_b}} (a_k \cdot b_l) \cdot B^{k+l-2}``

    **Usage**
    ```jldoctest
    julia> HighPrecisionInt(15) * HighPrecisionInt(8)
    HighPrecisionInt(120, coeffs=[120])

    julia> HighPrecisionInt(15) * HighPrecisionInt(-8)
    HighPrecisionInt(-120, coeffs=[120])
    
    julia> HighPrecisionInt(123) * HighPrecisionInt(0)
    HighPrecisionInt(0, coeffs=[])
    
    julia> hpi_large_1 = HighPrecisionInt(BigInt(123456789012345))
    HighPrecisionInt(123456789012345, coeffs=[2249056121, 28744])
    
    julia> hpi_large_2 = HighPrecisionInt(BigInt(987654321098765))
    HighPrecisionInt(987654321098765, coeffs=[821579789, 229956])

    julia> hpi_large_1 * hpi_large_2
    HighPrecisionInt(121932631137021071359549253925, coeffs=[1371679013, 3356926734, 2315013882, 1])
    
    julia> hpi_large_3 = HighPrecisionInt(BigInt(12345678901234567890123))
    HighPrecisionInt(12345678901234567890123, coeffs=[1900168395, 1119243894, 669])
    
    julia> hpi_large_4 = HighPrecisionInt(-BigInt(98765432109876543210987))
    HighPrecisionInt(-98765432109876543210987, coeffs=[509593067, 364226111, 5354])
    
    julia> hpi_large_3 * hpi_large_4
    HighPrecisionInt(-1219326311370217952261797134336296860222381401, coeffs=[1209687385, 2842068862, 4008437551, 4196447926, 3583277])
    ```
  ### 🧩 Macros

  - **Construct from String:** `@hpi_str(s::String)`

    Constructs a [`HighPrecisionInt`](@ref) from a string literal `s` (decimal or "0x" prefixed hex).

    **Usage**
    ```jldoctest
    julia> hpi"12345678901234567890"
    HighPrecisionInt(12345678901234567890, coeffs=[3944680146, 2874452364])

    julia> hpi"-0xABCDEF"
    HighPrecisionInt(-11259375, coeffs=[11259375])

    julia> hpi"1234567890123456789012345678901234567890"
    HighPrecisionInt(1234567890123456789012345678901234567890, coeffs=[3460238034, 2898026390, 3235640248, 2697535605, 3])
    ```
  ### 🖥️ Display

    **`@show` Macro:** `Base.show(io::IO, hpi::HighPrecisionInt)`

    Defines how [`HighPrecisionInt`](@ref) are displayed when printed, showing their equivalent decimal value and coefficients in little-endian order. 

    **Usage**
    ```jldoctest
    julia> hpi_1 = HighPrecisionInt(99999999999999999999)
    HighPrecisionInt(99999999999999999999, coeffs=[1775798783, 1260799867, 23])

    julia> hpi_2 = HighPrecisionInt(-1234567890)
    HighPrecisionInt(-1234567890, coeffs=[1234567890])

    julia> hpi_3 = HighPrecisionInt(0)
    HighPrecisionInt(0, coeffs=[0])
    ```
  ## 🧪 Verification Examples

  To ensure the correctness of the [`HighPrecisionInt`](@ref) , the following examples demonstrate various operations and verify their results against Julia's built-in `BigInt` type.

  **Examples**
  ```jldoctest

  using HighPrecisionArithmetic

  # Define large test numbers 
  const TEST_VAL_BIG_POS_1 = big"123456789012345678901234567890"
  const TEST_VAL_BIG_POS_2 = big"987654321098765432109876543210" 
  const TEST_VAL_BIG_NEG_1 = big"-543210987654321098765432109876"
  const TEST_VAL_BIG_NEG_2 = big"-111222333444555666777888999000"
  const TEST_VAL_BIG_ZERO = BigInt(0)

  # 1. Creation and Conversion Verification
  @assert BigInt(HighPrecisionInt(-BigInt(2)^150 - 1))              == (-BigInt(2)^150 - 1)
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_ZERO))               == TEST_VAL_BIG_ZERO
  @assert BigInt(HighPrecisionInt(BigInt(HIGH_PRECISION_BASE - 1))) == BigInt(HIGH_PRECISION_BASE - 1)
  @assert BigInt(HighPrecisionInt(BigInt(HIGH_PRECISION_BASE)))     == BigInt(HIGH_PRECISION_BASE) 
  @assert BigInt(HighPrecisionInt(BigInt(2)^64 + 1))                == BigInt(2)^64 + 1
  @assert BigInt(HighPrecisionInt(-BigInt(2)^64 - 1))               == -BigInt(2)^64 - 1 

  # 2. Unary Operations Verification
  @assert BigInt(abs(HighPrecisionInt(TEST_VAL_BIG_POS_1))) == abs(TEST_VAL_BIG_POS_1)
  @assert BigInt(-HighPrecisionInt(TEST_VAL_BIG_POS_1))     == -TEST_VAL_BIG_POS_1
  @assert BigInt(abs(HighPrecisionInt(TEST_VAL_BIG_NEG_1))) == abs(TEST_VAL_BIG_NEG_1)
  @assert BigInt(-HighPrecisionInt(TEST_VAL_BIG_NEG_1))     == -TEST_VAL_BIG_NEG_1
  @assert BigInt(abs(HighPrecisionInt(TEST_VAL_BIG_ZERO)))  == abs(TEST_VAL_BIG_ZERO)
  @assert BigInt(-HighPrecisionInt(TEST_VAL_BIG_ZERO))      == -TEST_VAL_BIG_ZERO

  # 3. Comparison Operators Verification
  @assert (HighPrecisionInt(TEST_VAL_BIG_POS_1) == HighPrecisionInt(TEST_VAL_BIG_POS_1)) == (TEST_VAL_BIG_POS_1 == TEST_VAL_BIG_POS_1)
  @assert (HighPrecisionInt(TEST_VAL_BIG_POS_1) != HighPrecisionInt(TEST_VAL_BIG_POS_2)) == (TEST_VAL_BIG_POS_1 != TEST_VAL_BIG_POS_2)
  @assert (HighPrecisionInt(TEST_VAL_BIG_POS_1) <  HighPrecisionInt(TEST_VAL_BIG_POS_2)) == (TEST_VAL_BIG_POS_1 <  TEST_VAL_BIG_POS_2)
  @assert (HighPrecisionInt(TEST_VAL_BIG_POS_2) >  HighPrecisionInt(TEST_VAL_BIG_POS_1)) == (TEST_VAL_BIG_POS_2 >  TEST_VAL_BIG_POS_1)
  @assert (HighPrecisionInt(TEST_VAL_BIG_NEG_2) <  HighPrecisionInt(TEST_VAL_BIG_NEG_1)) == (TEST_VAL_BIG_NEG_2 <  TEST_VAL_BIG_NEG_1) 
  @assert (HighPrecisionInt(TEST_VAL_BIG_POS_1) >  HighPrecisionInt(TEST_VAL_BIG_NEG_1)) == (TEST_VAL_BIG_POS_1 >  TEST_VAL_BIG_NEG_1)
  @assert (HighPrecisionInt(TEST_VAL_BIG_ZERO) ==  HighPrecisionInt(0))                  == (TEST_VAL_BIG_ZERO  == BigInt(0))

  # 4. Addition Verification
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_POS_1) + HighPrecisionInt(TEST_VAL_BIG_POS_2)) == (TEST_VAL_BIG_POS_1 + TEST_VAL_BIG_POS_2)
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_NEG_1) + HighPrecisionInt(TEST_VAL_BIG_NEG_2)) == (TEST_VAL_BIG_NEG_1 + TEST_VAL_BIG_NEG_2)
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_POS_2) + HighPrecisionInt(TEST_VAL_BIG_NEG_1)) == (TEST_VAL_BIG_POS_2 + TEST_VAL_BIG_NEG_1)
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_NEG_2) + HighPrecisionInt(TEST_VAL_BIG_POS_1)) == (TEST_VAL_BIG_NEG_2 + TEST_VAL_BIG_POS_1)
  @assert BigInt(HighPrecisionInt(BigInt(2)^100)      + HighPrecisionInt(-BigInt(2)^100))     == TEST_VAL_BIG_ZERO # Sum to zero
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_POS_1) + HighPrecisionInt(TEST_VAL_BIG_ZERO))  == TEST_VAL_BIG_POS_1 # Add zero
  @assert BigInt(HighPrecisionInt(typemax(UInt64))    + HighPrecisionInt(1))                  == BigInt(typemax(UInt64)) + 1 # Carry test

  # 5. Subtraction Verification
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_POS_2) - HighPrecisionInt(TEST_VAL_BIG_POS_1)) == (TEST_VAL_BIG_POS_2 - TEST_VAL_BIG_POS_1)
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_POS_1) - HighPrecisionInt(TEST_VAL_BIG_POS_2)) == (TEST_VAL_BIG_POS_1 - TEST_VAL_BIG_POS_2) 
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_NEG_1) - HighPrecisionInt(TEST_VAL_BIG_NEG_2)) == (TEST_VAL_BIG_NEG_1 - TEST_VAL_BIG_NEG_2) 
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_NEG_2) - HighPrecisionInt(TEST_VAL_BIG_NEG_1)) == (TEST_VAL_BIG_NEG_2 - TEST_VAL_BIG_NEG_1) 
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_POS_1) - HighPrecisionInt(TEST_VAL_BIG_NEG_1)) == (TEST_VAL_BIG_POS_1 - TEST_VAL_BIG_NEG_1) 
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_NEG_1) - HighPrecisionInt(TEST_VAL_BIG_POS_1)) == (TEST_VAL_BIG_NEG_1 - TEST_VAL_BIG_POS_1) 
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_POS_1) - HighPrecisionInt(TEST_VAL_BIG_ZERO))  ==  TEST_VAL_BIG_POS_1
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_ZERO)  - HighPrecisionInt(TEST_VAL_BIG_POS_1)) == -TEST_VAL_BIG_POS_1

  # 6. Multiplication Verification
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_POS_1) * HighPrecisionInt(TEST_VAL_BIG_POS_2)) == (TEST_VAL_BIG_POS_1 * TEST_VAL_BIG_POS_2)
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_NEG_1) * HighPrecisionInt(TEST_VAL_BIG_POS_2)) == (TEST_VAL_BIG_NEG_1 * TEST_VAL_BIG_POS_2)
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_POS_1) * HighPrecisionInt(TEST_VAL_BIG_NEG_2)) == (TEST_VAL_BIG_POS_1 * TEST_VAL_BIG_NEG_2)
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_NEG_1) * HighPrecisionInt(TEST_VAL_BIG_NEG_2)) == (TEST_VAL_BIG_NEG_1 * TEST_VAL_BIG_NEG_2)
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_POS_1) * HighPrecisionInt(TEST_VAL_BIG_ZERO))  == TEST_VAL_BIG_ZERO 
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_ZERO)  * HighPrecisionInt(TEST_VAL_BIG_POS_1)) == TEST_VAL_BIG_ZERO
  @assert BigInt(HighPrecisionInt(TEST_VAL_BIG_ZERO)  * HighPrecisionInt(TEST_VAL_BIG_ZERO))  == TEST_VAL_BIG_ZERO
  @assert BigInt(HighPrecisionInt(BigInt(HIGH_PRECISION_BASE - 1)) * HighPrecisionInt(2))     == BigInt(HIGH_PRECISION_BASE - 1) * 2 

  # 7. Macro Verification
  @assert BigInt(hpi"1234567890123456789012345678901234567890") == BigInt("1234567890123456789012345678901234567890")
  @assert BigInt(hpi"-0xABCDEF") == BigInt("-0xABCDEF")
  @assert BigInt(hpi("0x" * "F"^(200))) == BigInt("0x" * "F"^(200)) 
  @assert BigInt(hpi"0") == BigInt(0)
  ```
