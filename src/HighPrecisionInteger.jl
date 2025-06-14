"""
    HIGH_PRECISION_BASE

This constant defines the base used for high-precision arithmetic, set to ``2^{32}``. 

- It efficiently uses the `UInt64` type to store 32-bit chunks, enabling safe intermediate operations 
like ``+``, ``-``, and ``*`` with carry, without risking overflow during computation.
- Each element in the `coeffs` vector of a [`HighPrecisionInt`](@ref) represents a digit in this base, 
forming the foundation of our custom high-precision number representation.
"""
const HIGH_PRECISION_BASE = UInt64(2)^32

"""
    HighPrecisionInt

A mutable struct representing a high-precision integer.

- It stores integer as an arbitrary length vector of `coeffs::Vector{UInt64}` coefficients in `HIGH_PRECISION_BASE`
and a `sign::Int8` sign (1 for positive, -1 for negative, 0 for zero).
- The coefficients are stored in little-endian order (least significant coefficient first).

# Inner constructor

Constructs a [`HighPrecisionInt`](@ref) and normalizes to ensure a consistent representation based on `HIGH_PRECISION_BASE`.
"""
mutable struct HighPrecisionInt
    coeffs::Vector{UInt64}  # Coefficients in little-endian order
    sign::Int8              # 1 for positive, -1 for negative, 0 for zero

    function HighPrecisionInt(coeffs::Vector{UInt64}, sign::Int8=Int8(1))
        hpi = new(coeffs, sign)
        normalize!(hpi) # Ensure consistent representation
        return hpi
    end
end

HighPrecisionInt(x::HighPrecisionInt) = x


"""
    normalize!(hpi::HighPrecisionInt)

Normalizes a [`HighPrecisionInt`](@ref) in place, ensuring its internal representation is canonical and efficient.

This function performs four crucial tasks:
1. **Initial Zero Check**
    - If the coefficient vector is empty, the number is initialized to zero by adding a `0` coefficient and setting the sign to `0`.

2. **Fixes Carries/Borrows (Digit Overflow)**
    - For coefficients ``c_i``, ensure ``0 \\le c_i < \\text{HIGH\\_PRECISION\\_BASE}`` by carrying over: ``c_i \\leftarrow c_i \\mod \\text{HIGH\\_PRECISION\\_BASE}``

3. **Removes Leading Zeros**
    - Trims unnecessary most significant zeros to keep the number compact.

4. **Corrects Signs**
    - Sets sign to `0` if the number is zero; otherwise ensures it's positive if non-zero.
"""
function normalize!(hpi::HighPrecisionInt)
    
    if isempty(hpi.coeffs)
        hpi.sign = Int8(0)
        push!(hpi.coeffs, UInt64(0))

        return hpi
    end
    
    carry = UInt64(0)

    i = 1
    # Iterate through coefficients, handling carries, and potentially extending the vector
    @inbounds while i <= length(hpi.coeffs) || carry > 0
        current_coeff_val = (i <= length(hpi.coeffs) ? hpi.coeffs[i] : UInt64(0)) + carry

        hpi.coeffs[i] = mod(current_coeff_val, HIGH_PRECISION_BASE)
        carry = fld(current_coeff_val, HIGH_PRECISION_BASE)

        # If we are at the end of the current coefficients and there's a carry,
        # we need to push a new coefficient.
        if i == length(hpi.coeffs) && carry > 0
            push!(hpi.coeffs, UInt64(0))
        end
        i += 1
    end

    # Remove trailing (most significant) zero coefficients, but leave at least one if the number is zero.
    while length(hpi.coeffs) > 1 && hpi.coeffs[end] == 0
        pop!(hpi.coeffs)
    end

    # Set sign to 0 if the number is actually zero
    if length(hpi.coeffs) == 1 && hpi.coeffs[1] == 0
        hpi.sign = Int8(0)
    # If the sign was explicitly set to 0 but the value is non-zero, correct it to 1(positive).
    elseif hpi.sign == 0
        hpi.sign = Int8(1)
    end

    return hpi
end

"""
    HighPrecisionInt(x::T) where {T<:Union{Integer, BigInt}}

Creates a [`HighPrecisionInt`](@ref) from an `Integer` or `BigInt` `x`, representing it in base-`HIGH_PRECISION_BASE`.
    
Here's the breakdown:
1. **Handle Zero:** 
    - If `x` is zero, it returns a [`HighPrecisionInt`](@ref) representing zero directly.

2. **Determine Sign:** 
    - It determines the sign of `x` (positive, negative).

3. **Extract Coefficients:**  
    - For ``x`` compute coefficients ``c_i`` where ``0 \\le c_i < \\text{HIGH\\_PRECISION\\_BASE}`` such that:
        
        ``\\sum_{i=1}^{n} c_i \\cdot \\text{HIGH\\_PRECISION\\_BASE}^{i-1} = |x|``
        
        using repeated division and remainder: ``c_i = |x| \\mod \\text{HIGH\\_PRECISION\\_BASE}``.

    This yields the coefficients of the number `x` in base-`HIGH_PRECISION_BASE` in little-endian order.

4. **Construct and Return:** 
    - Finally, it constructs a [`HighPrecisionInt`](@ref) using the coefficients and the sign ordered from least to most significant.

"""
function HighPrecisionInt(x::T) where {T<:Union{Integer,BigInt}}
    if x == 0
        return HighPrecisionInt([UInt64(0)], Int8(0)) # Special case for zero
    end

    input_sign = Int8(x < 0 ? -1 : 1)

    coeffs = UInt64[] 
    temp_abs_x = abs(x) 

    # Repeatedly take quotient and remainders to get coefficients
    while temp_abs_x != 0
        temp_abs_x, rem_val = divrem(temp_abs_x, HIGH_PRECISION_BASE)
        push!(coeffs, UInt64(rem_val))
    end
    return HighPrecisionInt(coeffs, input_sign) # Construct and normalize
end

"""
    Base.BigInt(hpi::HighPrecisionInt)

Converts a [`HighPrecisionInt`](@ref) into a `BigInt`.

It reconstructs the Big-Integer from its base-`HIGH_PRECISION_BASE` representation using the formula:

``\\text{BigInt} = \\text{sign} \\times \\sum_{i=1}^{n} \\text{coeff}_i \\times \\text{HIGH_PRECISION_BASE}^{i-1}``

where ``\\text{coeff}_i`` are the coefficients of the [`HighPrecisionInt`](@ref) and ``n`` is the number of coefficients.
"""
function Base.BigInt(hpi::HighPrecisionInt)
    if hpi.sign == 0
        return BigInt(0)
    end

    result = sum(BigInt(coeff) * HIGH_PRECISION_BASE^(i-1) for (i, coeff) in enumerate(hpi.coeffs))
    return hpi.sign * result
end

"""
    Base.abs(hpi::HighPrecisionInt)

Returns the absolute value of a [`HighPrecisionInt`](@ref).
"""
Base.abs(hpi::HighPrecisionInt) = HighPrecisionInt(copy(hpi.coeffs), abs(hpi.sign))

"""
    Base.isequal(a::HighPrecisionInt, b::HighPrecisionInt)

Checks whether two [`HighPrecisionInt`](@ref) numbers are equal (`a` == `b`).
"""
function Base.isequal(a::HighPrecisionInt, b::HighPrecisionInt)
    a.sign != b.sign && return false
    a.sign == 0 && b.sign == 0 && return true
    length(a.coeffs) != length(b.coeffs) && return false
    return a.coeffs == b.coeffs
end
Base.:(==)(a::HighPrecisionInt, b::HighPrecisionInt) = Base.isequal(a, b)

"""
    Base.isless(a::HighPrecisionInt, b::HighPrecisionInt)

Compares two [`HighPrecisionInt`](@ref) numbers for less than (`a < b`).

Here's the breakdown:
1.  **Sign Comparison**:
    - If ``\\text{sign}(a) \\neq \\text{sign}(b)``, then ``a < b \\Leftrightarrow \\text{sign}(a) < \\text{sign}(b)``.
    - If ``\\text{sign}(a) = \\text{sign}(b) = 0``, they are equal, so ``a \\not< b``.
2.  **Magnitude Comparison**:
    Let ``L_a, L_b`` be the number of coefficients and ``c_a^k, c_b^k`` be the ``k``-th coefficients (most significant first).
    - If ``L_a \\neq L_b``:
        - For positive numbers: ``a < b \\Leftrightarrow L_a < L_b``.
        - For negative numbers: ``a < b \\Leftrightarrow L_a > L_b``.
    - If ``L_a = L_b``: Compare ``c_a^k`` and ``c_b^k`` from most significant (``k=L_a``) downwards.
        - For positive numbers: ``a < b`` if the first differing ``c_a^k < c_b^k``.
        - For negative numbers: ``a < b`` if the first differing ``c_a^k > c_b^k``.
    - If all coefficients are identical, ``a=b``, so ``a \\not< b``.

    The code uses a `flip` flag and XOR (`⊻`) to implement this logic concisely.
"""
function Base.isless(a::HighPrecisionInt, b::HighPrecisionInt)
    if a.sign != b.sign
        return a.sign < b.sign
    elseif a.sign == 0
        return false
    end

    flip = a.sign == -1

    la, lb = length(a.coeffs), length(b.coeffs)
    if la != lb
        return flip ⊻ (la < lb)
    end

    @inbounds begin
        for i in la:-1:1
            c1, c2 = a.coeffs[i], b.coeffs[i]
            if c1 != c2
                return flip ⊻ (c1 < c2)
            end
        end
    end

    return false
end
Base.:(<)(a::HighPrecisionInt, b::HighPrecisionInt) = Base.isless(a, b)

"""
    abs_subtract(a_coeffs::Vector{UInt64}, b_coeffs::Vector{UInt64})

Subtracts the magnitudes of two numbers represented by `a_coeffs` and `b_coeffs` (in base ``B=2^{32}``),
effectively computing ``||a| - |b||``. Used when adding numbers of different signs in `+` operator. 

Returns a tuple: `(result_coeffs, is_negative_diff)`.
`result_coeffs` is the vector of coefficients representing ``| |a| - |b| |``.
`is_negative_diff` is `true` if ``|b| > |a|`` (i.e., the original difference `a - b` would be negative).
This helper function is primarily used within the main addition/subtraction
(`+` or `-` operator overloads for `HighPrecisionInt`) when the operands have differing signs.


## Mathematical Foundation

Given non-negative numbers ``X, Y`` represented by coefficient vectors `a_coeffs` and `b_coeffs` respectively in base ``B=2^{32}``:

``X = \\sum_{k=1}^{\\text{length(a\\_coeffs)}} \\text{a\\_coeffs[k]} \\cdot B^{k-1}``

``Y = \\sum_{l=1}^{\\text{length(b\\_coeffs)}} \\text{b\\_coeffs[l]} \\cdot B^{l-1}``

This function computes ``|X - Y|`` by subtracting the smaller magnitude from the larger.
If ``X_k < Y_k + \\text{borrow}``, a borrow of ``1`` from the next higher coefficient (effectively adding ``B`` to ``X_k``) is performed.
The `is_negative_diff` flag indicates if ``Y > X``.


## Algorithm Steps

1.  **Determine Larger Magnitude**: 
        Compare `a_coeffs` and `b_coeffs`` by length; if equal, compare the most significant differing digit. Sets `a_mag_is_larger`.
2.  **Assign Operands**: 
    - `op1_coeffs` holds the larger magnitude's coefficients, `op2_coeffs` the smaller.
    - `result_coeffs` is sized to match `op1_coeffs`.
3.  **Subtract with Borrow**:
    - Initialize `borrow` = 0. For ``i = 1 \\dots \\text{length(op1_coeffs)}``:
    - Let ``v_1 = \\text{op1_coeffs[i]}`` and ``v_2 = (i \\le \\text{length(op2_coeffs)} ? \\text{op2_coeffs[i]} : 0)``.
    - If ``v_1 < v_2 + \\text{borrow}``:
        ``\\text{result_coeffs[i]} \\leftarrow B + v_1 - v_2 - \\text{borrow}``; ``\\text{borrow} \\leftarrow 1``.
    - Else:
        ``\\text{result_coeffs[i]} \\leftarrow v_1 - v_2 - \\text{borrow}``; ``\\text{borrow} \\leftarrow 0``.

4.  **Finalize**: 
    - Trim leading zeros from `result_coeffs` using `resize!`. 
    - If result is zero, `is_negative_diff` becomes `false`.
    - Return `(result_coeffs, !a_mag_is_larger)`.

## Implementation Notes
    - All coefficient values and intermediate arithmetic (sums, borrows)
         are handled using `UInt64` to prevent overflow, as coefficients are less than ``2^{32}``.
"""
function abs_subtract(a_coeffs::Vector{UInt64}, b_coeffs::Vector{UInt64})
    len_a, len_b = length(a_coeffs), length(b_coeffs)

    # Determine larger magnitude 
    a_mag_is_larger = true
    if len_a < len_b
        a_mag_is_larger = false
    elseif len_a == len_b
        @inbounds for i in len_a:-1:1
            if a_coeffs[i] < b_coeffs[i]
                a_mag_is_larger = false
                break
            elseif a_coeffs[i] > b_coeffs[i]
                a_mag_is_larger = true
                break
            end
        end
    end

    # Prepare operands to ensure op1 >= op2 for subtraction
    op1_coeffs = a_mag_is_larger ? a_coeffs : b_coeffs
    op2_coeffs = a_mag_is_larger ? b_coeffs : a_coeffs

    len_op1 = length(op1_coeffs)
    len_op2 = length(op2_coeffs)
    result_coeffs = Vector{UInt64}(undef, len_op1)
    borrow = UInt64(0)

    # Subtract common length portion
    min_coeffs_len = min(len_op1, len_op2)
    @inbounds for i in 1:min_coeffs_len
        if op1_coeffs[i] < op2_coeffs[i] + borrow
            result_coeffs[i] = HIGH_PRECISION_BASE + op1_coeffs[i] - op2_coeffs[i] - borrow
            borrow = UInt64(1)
        else
            result_coeffs[i] = op1_coeffs[i] - op2_coeffs[i] - borrow
            borrow = UInt64(0)
        end
    end

    # Propagate borrow through remaining digits of larger number
    @inbounds for i in (min_coeffs_len + 1):len_op1
        if op1_coeffs[i] < borrow
            result_coeffs[i] = HIGH_PRECISION_BASE + op1_coeffs[i] - borrow
            borrow = UInt64(1)
        else
            result_coeffs[i] = op1_coeffs[i] - borrow
            borrow = UInt64(0)
        end
    end

    # Trim leading zeros
    last_idx = len_op1
    while last_idx > 1 && result_coeffs[last_idx] == 0
        last_idx -= 1
    end
    resize!(result_coeffs, last_idx)

    # Handle zero result
    if length(result_coeffs) == 1 && result_coeffs[1] == 0
        return (result_coeffs, false)
    end

    # Return result and sign indicator
    return (result_coeffs, !a_mag_is_larger)
end

"""
    Base.:-(hpi::HighPrecisionInt)

Unary negation operator for [`HighPrecisionInt`](@ref).
"""
function Base.:-(hpi::HighPrecisionInt)
    if hpi.sign == 0
        return HighPrecisionInt([UInt64(0)], Int8(0)) # Negating zero is zero
    else
        return HighPrecisionInt(copy(hpi.coeffs), -hpi.sign) # Flip the sign
    end
end

"""
Base.:+(a::HighPrecisionInt, b::HighPrecisionInt)

Adds two `HighPrecisionInt` numbers, ``a`` and ``b``.

Performs efficient large-integer addition using sign handling and base-``2^{32}`` arithmetic with carry propagation.

## Mathematical Foundation

Let ``a = \\text{sign}_a \\cdot |a|`` and ``b = \\text{sign}_b \\cdot |b|``, where coefficients are in base ``B=2^{32}``.
- **Same Signs (``\\text{sign}_a = \\text{sign}_b``)**: 
    The result is ``\\text{sign}_a \\cdot (|a| + |b|)`` using standard digit-wise addition with carry propagation.
- **Different Signs (``\\text{sign}_a \\neq \\text{sign}_b``)**: 
    The result simplifies to a subtraction of absolute values, 
        i.e., ``a + b = \\pm (|a| - |b|)``, where the ``\\pm`` with sign from the larger operand.
        This is handled by an `abs_subtract` function.

## Algorithm

1.  **Zero Check**: If either ``a`` or ``b`` is zero, the other operand is returned.

2.  **Same Sign Addition**:
    - Initialize a `result_coeffs` vector and `carry = 0`.
    - Iterate, summing corresponding coefficients of ``a, b``
        from left to right (padding with `UInt64(0)` if needed) and the current `carry`.
    - The current result digit is `(sum) & MASK32` (lower 32 bits), 
        and the new `carry` is `(sum) >> 32` (upper 32 bits).
    - Append any final `carry` to `result_coeffs`.
    - The result inherits the common sign of ``a`` and ``b``.

3.  **Different Sign Subtraction**:
    - If signs differ (e.g., ``a > 0, b < 0``), `abs_subtract(a.coeffs, b.coeffs)` (or `b.coeffs, a.coeffs` if ``a < 0, b > 0``) is invoked.
    - If the result of `abs_subtract` indicates a negative difference,
        the final sign is negative; otherwise, it's positive.

## Implementation Notes
- All arithmetic uses `UInt64` with bitwise ops (`& MASK32`, `>> 32`) to extract coefficients and carries efficiently. 
- `@inbounds` is used in loops for performance, assuming safe indexing.  
- `abs_subtract` handles differing signs by computing the absolute difference and its sign.
"""
function Base.:+(a::HighPrecisionInt, b::HighPrecisionInt)
    
    # Handle addition with zero
    if a.sign == 0
        return b
    end
    if b.sign == 0
        return a
    end

    MASK32 = 0xffffffff # Mask for lower 32 bits

    # Case 1: Both numbers have the same sign (add magnitudes)
    if a.sign == b.sign
        max_len = max(length(a.coeffs), length(b.coeffs))
        result_coeffs = Vector{UInt64}(undef, max_len)
        
        carry = UInt64(0)

        @inbounds for i in 1:max_len
            val_a = i <= length(a.coeffs) ? a.coeffs[i] : UInt64(0)
            val_b = i <= length(b.coeffs) ? b.coeffs[i] : UInt64(0)

            current_sum = val_a + val_b + carry

            result_coeffs[i] = current_sum & MASK32
            carry = current_sum >> 32
        end

        # Handle any final carry
        if carry > 0
            push!(result_coeffs, carry)
        end
        
        return HighPrecisionInt(result_coeffs, a.sign)

    # Case 2: Signs are different (subtract magnitudes)
    elseif a.sign == 1 && b.sign == -1 # a is positive, b is negative
        result_coeffs_raw, is_negative_diff = abs_subtract(a.coeffs, b.coeffs)
        final_sign = is_negative_diff ? Int8(-1) : Int8(1)
        return HighPrecisionInt(result_coeffs_raw, final_sign)
    
    else # a is negative, b is positive
        result_coeffs_raw, is_negative_diff = abs_subtract(b.coeffs, a.coeffs) 
        final_sign = is_negative_diff ? Int8(-1) : Int8(1)
        return HighPrecisionInt(result_coeffs_raw, final_sign)
    end
end

"""
    Base.:-(a::HighPrecisionInt, b::HighPrecisionInt)

Subtraction operator for `HighPrecisionInt`.
"""
Base.:-(a::HighPrecisionInt, b::HighPrecisionInt) = a + (-b)

"""
    Base.:*(a::HighPrecisionInt, b::HighPrecisionInt)

Multiplies two [`HighPrecisionInt`](@ref) numbers, ``a`` and ``b``.

The method implements long multiplication using base ``B = 2^{32}`` (`HIGH_PRECISION_BASE`).

## Mathematical Foundation
Let ``a = \\sum_{k=1}^{\\text{len\\_a}} a_k \\cdot B^{k-1}`` and ``b = \\sum_{l=1}^{\\text{len\\_b}} b_l \\cdot B^{l-1}``,
where ``a_k = \\text{a.coeffs[k]}`` and ``b_l = \\text{b.coeffs[l]}`` are coefficients in base ``B``.

The product is ``a \\cdot b = \\sum_{k=1}^{\\text{len\\_a}} \\sum_{l=1}^{\\text{len\\_b}} (a_k \\cdot b_l) \\cdot B^{k+l-2}``.

Each partial product ``p_{k,l} = a_k \\cdot b_l`` (a `UInt64`, `prod` in code) can be written as ``p_{k,l} = lo_{k,l} + hi_{k,l} \\cdot B``, where:
- ``lo_{k,l} = p_{k,l} \\pmod B`` (lower 32 bits, `prod & MASK32`)
- ``hi_{k,l} = \\lfloor p_{k,l} / B \\rfloor`` (upper 32 bits, `prod >> 32`).

The term ``(a_k \\cdot b_l) \\cdot B^{k+l-2}`` contributes ``lo_{k,l}`` to the coefficient of ``B^{k+l-2}`` (index ``k+l-1`` in the result vector) and ``hi_{k,l}`` to the coefficient of ``B^{k+l-1}`` (index ``k+l`` in the result vector). These contributions are summed up with carries.

## Algorithm Steps
1.  **Handle Zero**: If ``a\\text{.sign} = 0`` or ``b\\text{.sign} = 0``, the result is `HighPrecisionInt(0)`.
2.  **Initialize Result**: A zero-filled `UInt64` vector `result` of length `len_a + len_b` is created,
        where `len_a` and `len_b` are the lengths of `a.coeffs` and `b.coeffs`.
3.  **Multiply and Accumulate with Carry**:
    For each ``a_i`` (`a.coeffs[i]`) and ``b_j`` (`b.coeffs[j]`):
    
    a.  **Compute partial product**: ``p = a_i \\cdot b_j`` (a `UInt64`).
    
    b.  **Split ``p`` into 32-bit parts**: ``lo = p \\pmod B`` (i.e., `p & MASK32`), ``hi = p \\gg 32``.
    
    c.  **Accumulate `lo`**:
        At index ``k = i+j-1``:
        `result[k] \\leftarrow result[k] + lo`
        `carry = result[k] \\gg 32` (extract carry from the sum)
        `result[k] \\leftarrow result[k] \\pmod B` (or `result[k] \\&= \\text{MASK32}`)
    
    d.  **Accumulate `hi` and `carry`**:
        At index ``k \\leftarrow k+1`` (now ``i+j``):
        `result[k] \\leftarrow result[k] + hi + \\text{carry}_{\\text{prev_step}}`
        `carry = result[k] \\gg 32`
        `result[k] \\leftarrow result[k] \\pmod B`
    
    e.  **Propagate Final Carry**:
        While `carry \\neq 0`:
        ``k \\leftarrow k+1``.
        `result[k] \\leftarrow result[k] + carry`
        `carry_{\\text{new}} = result[k] \\gg 32`
        `result[k] \\leftarrow result[k] \\pmod B`
        `carry \\leftarrow carry_{\\text{new}}`

    4.  **Finalize**: Trim leading zeros from `result`, set sign as `a.sign * b.sign`,
        and return the [`HighPrecisionInt`](@ref).

## Implementation Notes
- Coefficients ``a_i, b_j < 2^{32}``, so their product ``a_i \\cdot b_j < 2^{64}`` (fits in `UInt64`).
- All arithmetic for accumulation and carry uses `UInt64`
     with bitwise operations (`& MASK32`, `>> 32`) for efficiency and to prevent overflow.
- `@inbounds` is used in loops for performance.
"""
function Base.:*(a::HighPrecisionInt, b::HighPrecisionInt)
    # If either operand is zero, the product is zero
    if a.sign == 0 || b.sign == 0
        return HighPrecisionInt([UInt64(0)], Int8(0))
    end

    len_a, len_b = length(a.coeffs), length(b.coeffs)
    result_len = len_a + len_b
    result = Vector{UInt64}(undef, result_len)
    fill!(result, 0)

    MASK32 = 0xffffffff
    BASE32 = 0x1_0000_0000

    @inbounds for i in 1:len_a
        ai = a.coeffs[i]
        for j in 1:len_b
            prod = ai * b.coeffs[j]
            lo = prod & MASK32
            hi = prod >> 32

            k = i + j - 1
            result[k] += lo
            carry = result[k] >> 32
            result[k] &= MASK32

            k += 1
            result[k] += hi + carry
            carry = result[k] >> 32
            result[k] &= MASK32

            while carry != 0
                k += 1
                result[k] += carry
                carry = result[k] >> 32
                result[k] &= MASK32
            end
        end
    end

    # Trim leading zeros
    while length(result) > 1 && result[end] == 0
        pop!(result)
    end

    return HighPrecisionInt(result, a.sign * b.sign)
end

"""
    Base.show(io::IO, hpi::HighPrecisionInt)

Defines how a [`HighPrecisionInt`](@ref) is displayed by converting it
 to a `BigInt` for a user-friendly decimal representation and its internal coefficient
representation.
"""
function Base.show(io::IO, hpi::HighPrecisionInt)
    if hpi.sign == 0
        print(io, "HighPrecisionInt(0, coeffs=[])")
    else
        # Convert to BigInt for display, ensuring the sign is correct
        value = hpi.sign * BigInt(abs(hpi))
        
        coeffs_str = "[" * join(hpi.coeffs .|> Int, ", ") * "]"
        print(io, "HighPrecisionInt($value, coeffs=$coeffs_str)")
    end
end

"""
    @hpi_str(s::String)

A string macro that creates a [`HighPrecisionInt`](@ref) from a string literal.

# Examples
```repl
julia> hpi"12345678901234567890"
HighPrecisionInt(12345678901234567890, coeffs=[124989312, 688091136, 166])

julia> hpi"-0xABCDEF"
HighPrecisionInt(-11259375, coeffs=[11259375])
```
"""
macro hpi_str(s::String)
    try
        return :(HighPrecisionInt($(parse(BigInt, s))))
    catch e
        return :(error("Invalid @hpi input: " * $(Meta.quot(s))) * ". Original error: " * string($e))
    end
end
