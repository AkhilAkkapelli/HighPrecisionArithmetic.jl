module HighPrecisionArithmetic

export HighPrecisionInt

# The base for our high-precision arithmetic. Using UInt64(2)^32 allows each coefficient
# to hold 32 bits of the number, leveraging the 64-bit UInt64 type to avoid overflow
# during intermediate calculations (e.g., additions and subtractions within normalize!).
const HIGH_PRECISION_BASE = UInt64(2)^32

"""
    HighPrecisionInt

A mutable struct representing a high-precision integer.
It stores the number as a vector of UInt64 coefficients in a chosen base (HIGH_PRECISION_BASE)
and an Int8 sign (1 for positive, -1 for negative, 0 for zero).
The coefficients are stored in little-endian order (least significant coefficient first).
"""
mutable struct HighPrecisionInt
    coeffs::Vector{UInt64} # Coefficients in little-endian order
    sign::Int8              # 1 for positive, -1 for negative, 0 for zero

    """
    Inner constructor for HighPrecisionInt.
    Normalizes the coefficients after creation to ensure a consistent representation.
    """
    function HighPrecisionInt(coeffs::Vector{UInt64}, sign::Int8=1)
        hpi = new(coeffs, sign)
        normalize!(hpi) # Ensure consistent representation
        return hpi
    end
end

HighPrecisionInt(x::HighPrecisionInt) = x

"""
    normalize!(hpi::HighPrecisionInt)

Normalizes a `HighPrecisionInt` in place.
This function performs two main tasks:
1. Handles carries/borrows across coefficients.
2. Removes leading zeros from the coefficients vector.
3. Sets the sign to 0 if the number becomes zero.
"""
function normalize!(hpi::HighPrecisionInt)
    carry = UInt64(0)

    i = 1
    # Iterate through coefficients, handling carries, and potentially extending the vector
    while i <= length(hpi.coeffs) || carry > 0
        current_coeff_val = (i <= length(hpi.coeffs) ? hpi.coeffs[i] : UInt64(0)) + carry

        hpi.coeffs[i] = Base.mod(current_coeff_val, HIGH_PRECISION_BASE)
        carry = Base.fld(current_coeff_val, HIGH_PRECISION_BASE)

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
    # If the sign was explicitly set to 0 but the value is non-zero, correct it to 1.
    elseif hpi.sign == 0 && !(length(hpi.coeffs) == 1 && hpi.coeffs[1] == 0)
        hpi.sign = Int8(1)
    end

    return hpi
end

"""
    HighPrecisionInt(x::T) where {T<:Union{Integer, BigInt}}

Constructs a `HighPrecisionInt` from a standard `Integer` or `BigInt`.
Converts the input number into its base-HIGH_PRECISION_BASE representation.
"""
function HighPrecisionInt(x::T) where {T<:Union{Integer, BigInt}}
    if x == 0
        return HighPrecisionInt([UInt64(0)], Int8(0)) # Special case for zero
    end

    input_sign = Int8(x < 0 ? -1 : 1)
    abs_x = BigInt(abs(x)) # Work with absolute value for coefficient conversion

    coeffs = UInt64[] # Initialize empty vector for coefficients
    temp_abs_x = abs_x # Use a temporary variable for the conversion process

    # Repeatedly take modulo and floor division to get coefficients
    while temp_abs_x > 0
        rem_val = Base.mod(temp_abs_x, BigInt(HIGH_PRECISION_BASE))
        push!(coeffs, UInt64(rem_val)) # Add the remainder as a coefficient
        temp_abs_x = Base.fld(temp_abs_x, BigInt(HIGH_PRECISION_BASE)) # Divide by base
    end
    return HighPrecisionInt(coeffs, input_sign) # Construct and normalize
end

"""
    Base.BigInt(hpi::HighPrecisionInt)

Converts a `HighPrecisionInt` back to a `BigInt`.
This allows for easy verification against Julia's native BigInt type.
"""
function Base.BigInt(hpi::HighPrecisionInt)
    if hpi.sign == 0
        return BigInt(0)
    end

    result = BigInt(0)
    power_of_base = BigInt(1) # Represents HIGH_PRECISION_BASE^k

    # Reconstruct the BigInt by summing (coefficient * base^power)
    for coeff in hpi.coeffs
        result += BigInt(coeff) * power_of_base
        power_of_base *= BigInt(HIGH_PRECISION_BASE) # Move to the next power of the base
    end
    return hpi.sign * result # Apply the sign
end

"""
    Base.abs(hpi::HighPrecisionInt)

Returns the absolute value of a `HighPrecisionInt`.
Creates a new HighPrecisionInt with a positive sign (1) but the same coefficients.
"""
function Base.abs(hpi::HighPrecisionInt)
    if hpi.sign == -1
        return HighPrecisionInt(copy(hpi.coeffs), Int8(1)) # Positive sign
    else
        return HighPrecisionInt(copy(hpi.coeffs), hpi.sign) # Sign remains the same if non-negative
    end
end

"""
    Base.isequal(a::HighPrecisionInt, b::HighPrecisionInt)

Checks for equality between two `HighPrecisionInt` instances.
Returns true if both sign and coefficients are identical.
"""
function Base.isequal(a::HighPrecisionInt, b::HighPrecisionInt)
    if a.sign != b.sign
        return false # Different signs means different numbers
    end
    if a.sign == 0 # Both are zero
        return true
    end
    if length(a.coeffs) != length(b.coeffs)
        return false # Different number of coefficients
    end
    return a.coeffs == b.coeffs # Compare coefficient vectors
end
Base.:(==)(a::HighPrecisionInt, b::HighPrecisionInt) = Base.isequal(a, b)

"""
    Base.isless(a::HighPrecisionInt, b::HighPrecisionInt)

Compares two `HighPrecisionInt` instances for less than (`a < b`).
Handles signs and then compares magnitudes.
"""
function Base.isless(a::HighPrecisionInt, b::HighPrecisionInt)
    # Handle mixed signs
    if a.sign == -1 && b.sign == 1
        return true # Negative is always less than positive
    end
    if a.sign == 1 && b.sign == -1
        return false # Positive is never less than negative
    end
    # Handle zeros
    if a.sign == 0 && b.sign == 0
        return false # 0 is not less than 0
    end
    if a.sign == 0
        return b.sign == 1 # 0 is less than positive
    end
    if b.sign == 0
        return a.sign == -1 # Negative is less than 0
    end

    # Handle same signs
    if a.sign == 1 # Both are positive
        if length(a.coeffs) < length(b.coeffs)
            return true # Fewer coefficients means smaller magnitude
        elseif length(a.coeffs) > length(b.coeffs)
            return false # More coefficients means larger magnitude
        else # Same number of coefficients, compare from most significant
            for i in length(a.coeffs):-1:1
                if a.coeffs[i] < b.coeffs[i]
                    return true
                elseif a.coeffs[i] > b.coeffs[i]
                    return false
                end
            end
            return false # They are equal
        end
    else # Both are negative (-1)
        # For negative numbers, the one with larger absolute value is actually smaller
        if length(a.coeffs) > length(b.coeffs)
            return true # e.g., -100 < -10, so longer magnitude is smaller (more negative)
        elseif length(a.coeffs) < length(b.coeffs)
            return false # e.g., -10 > -100, so shorter magnitude is larger (less negative)
        else # Same number of coefficients, compare from most significant (reversed logic)
            for i in length(a.coeffs):-1:1
                if a.coeffs[i] > b.coeffs[i] # e.g., -50 < -40
                    return true
                elseif a.coeffs[i] < b.coeffs[i] # e.g., -40 > -50
                    return false
                end
            end
            return false # They are equal
        end
    end
end
Base.:(<)(a::HighPrecisionInt, b::HighPrecisionInt) = Base.isless(a, b)


"""
    abs_subtract(a_coeffs::Vector{UInt64}, b_coeffs::Vector{UInt64})

Performs absolute subtraction of two positive numbers represented by coefficient vectors.
Returns a tuple: (result_coeffs, is_negative_diff).
`is_negative_diff` is true if |b| > |a| (i.e., the result would be negative if a - b was computed).
This helper is used for addition/subtraction where signs differ.
"""
function abs_subtract(a_coeffs::Vector{UInt64}, b_coeffs::Vector{UInt64})
    # Determine which magnitude is larger
    a_mag_is_larger = true
    if length(a_coeffs) < length(b_coeffs)
        a_mag_is_larger = false
    elseif length(a_coeffs) == length(b_coeffs)
        for i in length(a_coeffs):-1:1
            if a_coeffs[i] < b_coeffs[i]
                a_mag_is_larger = false
                break
            elseif a_coeffs[i] > b_coeffs[i]
                a_mag_is_larger = true
                break
            end
        end
    end

    # Assign operands based on which magnitude is larger to ensure positive result (abs diff)
    min_len = min(length(a_coeffs), length(b_coeffs))
    max_len = max(length(a_coeffs), length(b_coeffs))

    op1_coeffs = a_mag_is_larger ? a_coeffs : b_coeffs # Larger magnitude
    op2_coeffs = a_mag_is_larger ? b_coeffs : a_coeffs # Smaller magnitude

    result_coeffs = zeros(UInt64, max_len)
    borrow = UInt64(0)

    # Perform subtraction digit by digit (coefficient by coefficient)
    for i in 1:max_len
        val1 = i <= length(op1_coeffs) ? op1_coeffs[i] : UInt64(0)
        val2 = i <= length(op2_coeffs) ? op2_coeffs[i] : UInt64(0)

        if val1 < val2 + borrow
            # Need to "borrow" from the next higher coefficient
            result_coeffs[i] = HIGH_PRECISION_BASE + val1 - val2 - borrow
            borrow = UInt64(1)
        else
            result_coeffs[i] = val1 - val2 - borrow
            borrow = UInt64(0)
        end
    end

    # Remove leading zeros from the result
    while length(result_coeffs) > 1 && result_coeffs[end] == 0
        pop!(result_coeffs)
    end

    # If the result is zero, indicate it
    if length(result_coeffs) == 1 && result_coeffs[1] == 0
        return (result_coeffs, false) # Result is 0, so no "negative difference"
    end

    # Return the absolute result and a boolean indicating if the original 'a' was smaller
    # This boolean determines the sign of the final result for (a + (-b)) or (a - b)
    return (result_coeffs, !a_mag_is_larger)
end

"""
    Base.:-(hpi::HighPrecisionInt)

Unary negation operator for `HighPrecisionInt`.
Changes the sign of the number, handling zero as a special case.
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

Addition operator for `HighPrecisionInt`.
Handles various sign combinations (same sign, different signs) by calling `abs_subtract`
when magnitudes need to be subtracted.
"""
function Base.:+(a::HighPrecisionInt, b::HighPrecisionInt)
    # Handle addition with zero
    if a.sign == 0
        return b
    end
    if b.sign == 0
        return a
    end

    # Case 1: Both numbers have the same sign (add magnitudes)
    if a.sign == b.sign
        max_len = max(length(a.coeffs), length(b.coeffs))
        result_coeffs = zeros(UInt64, max_len)
        carry = UInt64(0)

        for i in 1:max_len
            val_a = i <= length(a.coeffs) ? a.coeffs[i] : UInt64(0)
            val_b = i <= length(b.coeffs) ? b.coeffs[i] : UInt64(0)

            current_sum = val_a + val_b + carry

            result_coeffs[i] = Base.mod(current_sum, HIGH_PRECISION_BASE)
            carry = Base.fld(current_sum, HIGH_PRECISION_BASE)
        end

        # Handle any final carry
        if carry > 0
            push!(result_coeffs, carry)
        end
        return HighPrecisionInt(result_coeffs, a.sign) # Result has the same sign

    # Case 2: Signs are different (subtract magnitudes)
    # For a + (-b) or (-a) + b, it becomes a subtraction of absolute values.
    # The sign of the result depends on which magnitude is larger.
    elseif a.sign == 1 && b.sign == -1 # a is positive, b is negative (e.g., 5 + (-3) = 5 - 3)
        result_coeffs_raw, is_negative_diff = abs_subtract(a.coeffs, b.coeffs)
        final_sign = is_negative_diff ? Int8(-1) : Int8(1) # If |b| > |a|, result is negative
        return HighPrecisionInt(result_coeffs_raw, final_sign)
    else # a is negative, b is positive (e.g., -5 + 3 = 3 - 5)
        result_coeffs_raw, is_negative_diff = abs_subtract(b.coeffs, a.coeffs) # Subtract |a| from |b|
        final_sign = is_negative_diff ? Int8(-1) : Int8(1) # If |a| > |b|, result is negative
        return HighPrecisionInt(result_coeffs_raw, final_sign)
    end
end

"""
    Base.:-(a::HighPrecisionInt, b::HighPrecisionInt)

Subtraction operator for `HighPrecisionInt`.
Implemented in terms of addition: `a - b` is `a + (-b)`.
"""
function Base.:-(a::HighPrecisionInt, b::HighPrecisionInt)
    return a + (-b) # Subtraction is addition with the negation of the second operand
end

"""
    Base.:*(a::HighPrecisionInt, b::HighPrecisionInt)

Multiplication operator for `HighPrecisionInt`.
Uses a standard polynomial multiplication approach, accumulating results in BigInt
to avoid intermediate overflows, then normalizing.
"""
function Base.:*(a::HighPrecisionInt, b::HighPrecisionInt)
    # If either operand is zero, the product is zero
    if a.sign == 0 || b.sign == 0
        return HighPrecisionInt([UInt64(0)], Int8(0))
    end

    len_a = length(a.coeffs)
    len_b = length(b.coeffs)

    # The maximum length of the product's raw coefficients before normalization
    result_coeffs_raw = zeros(BigInt, len_a + len_b - 1)

    # Perform polynomial multiplication (Karatsuba or other optimized algorithms could be used for very large numbers)
    for i in 1:len_a
        for j in 1:len_b
            result_coeffs_raw[i + j - 1] += BigInt(a.coeffs[i]) * BigInt(b.coeffs[j])
        end
    end

    # Normalize the raw product coefficients (handle carries)
    normalized_coeffs_uint64 = UInt64[]
    carry = BigInt(0)

    for i in 1:length(result_coeffs_raw)
        current_val = result_coeffs_raw[i] + carry
        push!(normalized_coeffs_uint64, UInt64(Base.mod(current_val, BigInt(HIGH_PRECISION_BASE))))
        carry = Base.fld(current_val, BigInt(HIGH_PRECISION_BASE))
    end
    # Add any remaining carry as new coefficients
    while carry > 0
        push!(normalized_coeffs_uint64, UInt64(Base.mod(carry, BigInt(HIGH_PRECISION_BASE))))
        carry = Base.fld(carry, BigInt(HIGH_PRECISION_BASE))
    end

    # Remove leading zeros from the final coefficients
    while length(normalized_coeffs_uint64) > 1 && normalized_coeffs_uint64[end] == 0
        pop!(normalized_coeffs_uint64)
    end

    # Determine the final sign of the product
    final_sign = Int8(a.sign * b.sign) # Sign is positive if signs are same, negative if different

    return HighPrecisionInt(normalized_coeffs_uint64, final_sign)
end

"""
    Base.show(io::IO, hpi::HighPrecisionInt)

Defines how a `HighPrecisionInt` object is displayed when printed.
Converts it to a BigInt for a user-friendly decimal representation.
"""
function Base.show(io::IO, hpi::HighPrecisionInt)
    if hpi.sign == 0
        print(io, "HighPrecisionInt(0)")
    else
        # Convert to BigInt for display, ensuring the sign is correct
        print(io, "HighPrecisionInt($(hpi.sign * BigInt(abs(hpi))))")
    end
end

end # module HighPrecisionArithmetic