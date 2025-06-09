# 🧮 High Precision Number

This module provides a custom `HighPrecisionInt` type for performing arithmetic operations on integers that exceed the standard `Int64` or `UInt128` limits in Julia. It achieves arbitrary precision by representing numbers as a vector of `UInt64` coefficients in a large base $2^{32}$, similar to how `BigInt` works internally.

---

## 🔧 Type Definitions

The core of the module is the `HighPrecisionInt` struct:

```julia
mutable struct HighPrecisionInt
    coeffs::Vector{UInt64}  # Coefficients in little-endian order (least significant first)
    sign::Int8              # 1 for positive, -1 for negative, 0 for zero
end
```

> 📌 The `HIGH_PRECISION_BASE` is defined as `UInt64(2)^32`. Each `UInt64` coefficient effectively stores 32 bits of the high-precision number, leveraging the remaining 32 bits for intermediate arithmetic operations and overflow prevention.

---

## ➕ Key Functions and Operators

### 🏗️ Constructors

- `HighPrecisionInt(coeffs::Vector{UInt64}, sign::Int8=1)`  
  → Creates a `HighPrecisionInt` from coefficients and optional sign. Automatically calls `normalize!`.

- `HighPrecisionInt(x::T) where {T<:Union{Integer, BigInt}}`  
  → Converts a standard Julia `Integer` or `BigInt` into a `HighPrecisionInt`.

---

### 🧰 Internal Utilities

- `normalize!(hpi::HighPrecisionInt)`  
  → Cleans up the representation by:
  - Handling carries/borrows
  - Removing leading zeros
  - Adjusting sign for zero

---

### 🔁 Conversions

- `Base.BigInt(hpi::HighPrecisionInt)`  
  → Converts to Julia's native `BigInt` type.

---

### ➕ Unary Operations

- `Base.abs(hpi::HighPrecisionInt)`  
  → Returns absolute value.

- `Base.:-(hpi::HighPrecisionInt)`  
  → Unary negation; flips the sign.

---

### ⚖️ Comparison Operators

- `Base.isequal(a::HighPrecisionInt, b::HighPrecisionInt)`  
  → Equality check. Aliased as `==`.

- `Base.isless(a::HighPrecisionInt, b::HighPrecisionInt)`  
  → Less-than check. Aliased as `<`.

---

### 🧮 Arithmetic Operators

- `Base.:+(a::HighPrecisionInt, b::HighPrecisionInt)`  
  → Addition with sign handling and `abs_subtract` fallback.

- `Base.:-(a::HighPrecisionInt, b::HighPrecisionInt)`  
  → Subtraction as `a + (-b)`.

- `Base.:*(a::HighPrecisionInt, b::HighPrecisionInt)`  
  → Polynomial-style multiplication using `BigInt` for intermediate results.

---

### 🖨️ Display

- `Base.show(io::IO, hpi::HighPrecisionInt)`  
  → Displays as equivalent decimal when printed.

---

## 🧪 Usage Examples

```julia
# Load the module
include("HighPrecisionNumber.jl")
using .HighPrecisionNumber

println("--- HighPrecisionInt Usage Examples ---")

# 1️⃣ Creation
val_pos = HighPrecisionInt(123)
println("HighPrecisionInt(123)       => $val_pos")

val_neg = HighPrecisionInt(-4567)
println("HighPrecisionInt(-4567)     => $val_neg")

val_zero = HighPrecisionInt(0)
println("HighPrecisionInt(0)         => $val_zero")

val_large_pos = HighPrecisionInt(typemax(UInt128))
println("HighPrecisionInt(typemax(UInt128)) => $val_large_pos")
println("  (Equivalent BigInt: $(BigInt(val_large_pos)))")

val_large_neg = HighPrecisionInt(-BigInt(2)^150 - 1)
println("HighPrecisionInt(-2^150 - 1) => $val_large_neg")
println("  (Equivalent BigInt: $(BigInt(val_large_neg)))")

# 2️⃣ Addition
a_pos = HighPrecisionInt(1000)
b_pos = HighPrecisionInt(2000)
println("\nAddition:")
println("$a_pos + $b_pos => $(a_pos + b_pos)")
println("Verification: $(BigInt(a_pos + b_pos) == 3000)")

a_neg = HighPrecisionInt(-1000)
b_neg = HighPrecisionInt(-2000)
println("$a_neg + $b_neg => $(a_neg + b_neg)")
println("Verification: $(BigInt(a_neg + b_neg) == -3000)")

# ➕ Mixed Sign Addition
a_pos_large = HighPrecisionInt(parse(BigInt, "98765432109876543210987654321098765"))
b_neg_small = HighPrecisionInt(-parse(BigInt, "12345"))
sum_diff_signs_pos = a_pos_large + b_neg_small
expected_sum_diff_signs_pos = parse(BigInt, "98765432109876543210987654321098765") - parse(BigInt, "12345")
println("$a_pos_large + $b_neg_small => $sum_diff_signs_pos")
println("Verification: $(BigInt(sum_diff_signs_pos) == expected_sum_diff_signs_pos)")

a_pos_small = HighPrecisionInt(parse(BigInt, "12345"))
b_neg_large = HighPrecisionInt(-parse(BigInt, "98765432109876543210987654321098765"))
sum_diff_signs_neg = a_pos_small + b_neg_large
expected_sum_diff_signs_neg = parse(BigInt, "12345") - parse(BigInt, "98765432109876543210987654321098765")
println("$a_pos_small + $b_neg_large => $sum_diff_signs_neg")
println("Verification: $(BigInt(sum_diff_signs_neg) == expected_sum_diff_signs_neg)")

# 3️⃣ Subtraction
c = HighPrecisionInt(5000)
d = HighPrecisionInt(2000)
println("\nSubtraction:")
println("$c - $d => $(c - d)")
println("Verification: $(BigInt(c - d) == 3000)")

println("$d - $c => $(d - c)")
println("Verification: $(BigInt(d - c) == -3000)")

# 4️⃣ Multiplication
x_pos = HighPrecisionInt(15)
y_pos = HighPrecisionInt(8)
println("\nMultiplication:")
println("$x_pos * $y_pos => $(x_pos * y_pos)")
println("Verification: $(BigInt(x_pos * y_pos) == 120)")

x_neg = HighPrecisionInt(-15)
y_pos = HighPrecisionInt(8)
println("$x_neg * $y_pos => $(x_neg * y_pos)")
println("Verification: $(BigInt(x_neg * y_pos) == -120)")

large_val_1_pos = HighPrecisionInt(parse(BigInt, "12345678901234567890123"))
large_val_2_neg = HighPrecisionInt(-parse(BigInt, "98765432109876543210987"))
product_large_signed = large_val_1_pos * large_val_2_neg
expected_product_large_signed = parse(BigInt, "12345678901234567890123") * -parse(BigInt, "98765432109876543210987")
println("\n$large_val_1_pos * $large_val_2_neg => $product_large_signed")
println("Verification: $(BigInt(product_large_signed) == expected_product_large_signed)")
```

---

This documentation provides a comprehensive overview of the `HighPrecisionNumber` module, its components, and how to use its various functions and operators effectively.
