using Test
using HighPrecisionArithmetic

@testset "HighPrecisionNumber.jl" begin

    # 1. HighPrecisionInt Creation
    @testset "HighPrecisionInt Creation" begin
        # Test positive integers
        hpi_1 = HighPrecisionInt(123)
        @test BigInt(hpi_1) == 123
        @test hpi_1.sign == 1
        @test hpi_1.coeffs == [0x0000007b] # 123 in UInt64

        # Test negative integers
        hpi_neg = HighPrecisionInt(-4567)
        @test BigInt(hpi_neg) == -4567
        @test hpi_neg.sign == -1
        @test hpi_neg.coeffs == [0x000011d7] # 4567 in UInt64

        # Test zero
        hpi_zero = HighPrecisionInt(0)
        @test BigInt(hpi_zero) == 0
        @test hpi_zero.sign == 0
        @test hpi_zero.coeffs == [0x00000000]

        # Test large positive integer (beyond Int64)
        large_int_pos = BigInt(2)^70 - 1
        hpi_large_pos = HighPrecisionInt(large_int_pos)
        @test BigInt(hpi_large_pos) == large_int_pos
        @test hpi_large_pos.sign == 1

        # Test large negative integer (beyond Int64)
        large_int_neg = -BigInt(2)^70 - 1
        hpi_large_neg = HighPrecisionInt(large_int_neg)
        @test BigInt(hpi_large_neg) == large_int_neg
        @test hpi_large_neg.sign == -1

        # Test with maximum UInt64 value to ensure base handling
        max_uint64 = typemax(UInt64)
        hpi_max_uint64 = HighPrecisionInt(max_uint64)
        @test BigInt(hpi_max_uint64) == max_uint64
        @test hpi_max_uint64.sign == 1

        # Test with HIGH_PRECISION_BASE itself
        hpi_base = HighPrecisionInt(BigInt(HighPrecisionArithmetic.HIGH_PRECISION_BASE))
        @test BigInt(hpi_base) == BigInt(HighPrecisionArithmetic.HIGH_PRECISION_BASE)
        @test hpi_base.coeffs == [0x00000000, 0x00000001]
    end

    # 2. Basic Arithmetic Operations
    @testset "Arithmetic Operations" begin
        a = HighPrecisionInt(1000)
        b = HighPrecisionInt(2000)
        c = HighPrecisionInt(-500)
        d = HighPrecisionInt(1500)
        e = HighPrecisionInt(-2500)
        z = HighPrecisionInt(0)

        # Addition
        @testset "Addition" begin
            @test BigInt(a + b) == BigInt(a) + BigInt(b) # 1000 + 2000 = 3000
            @test BigInt(a + c) == BigInt(a) + BigInt(c) # 1000 + (-500) = 500
            @test BigInt(c + a) == BigInt(c) + BigInt(a) # -500 + 1000 = 500
            @test BigInt(c + e) == BigInt(c) + BigInt(e) # -500 + (-2500) = -3000
            @test BigInt(a + z) == BigInt(a) # 1000 + 0 = 1000
            @test BigInt(z + c) == BigInt(c) # 0 + (-500) = -500
        end

        # Subtraction
        @testset "Subtraction" begin
            @test BigInt(b - a) == BigInt(b) - BigInt(a) # 2000 - 1000 = 1000
            @test BigInt(a - b) == BigInt(a) - BigInt(b) # 1000 - 2000 = -1000
            @test BigInt(a - c) == BigInt(a) - BigInt(c) # 1000 - (-500) = 1500
            @test BigInt(c - a) == BigInt(c) - BigInt(a) # -500 - 1000 = -1500
            @test BigInt(c - e) == BigInt(c) - BigInt(e) # -500 - (-2500) = 2000
            @test BigInt(a - z) == BigInt(a) # 1000 - 0 = 1000
            @test BigInt(z - c) == -BigInt(c) # 0 - (-500) = 500
        end

        # Multiplication
        @testset "Multiplication" begin
            x = HighPrecisionInt(15)
            y = HighPrecisionInt(8)
            @test BigInt(x * y) == BigInt(x) * BigInt(y) # 15 * 8 = 120

            x_neg = HighPrecisionInt(-15)
            @test BigInt(x_neg * y) == BigInt(x_neg) * BigInt(y) # -15 * 8 = -120

            y_neg = HighPrecisionInt(-8)
            @test BigInt(x * y_neg) == BigInt(x) * BigInt(y_neg) # 15 * -8 = -120

            @test BigInt(x_neg * y_neg) == BigInt(x_neg) * BigInt(y_neg) # -15 * -8 = 120

            @test BigInt(x * z) == 0 # 15 * 0 = 0
            @test BigInt(z * y) == 0 # 0 * 8 = 0
        end

        # Large Number Arithmetic
        @testset "Large Number Arithmetic" begin
            # Large addition (magnitudes sum up to new coefficients)
            large_a = HighPrecisionInt(BigInt(2)^60 + 10)
            large_b = HighPrecisionInt(BigInt(2)^60 + 20)
            @test BigInt(large_a + large_b) == (BigInt(2)^60 + 10) + (BigInt(2)^60 + 20)

            # Large subtraction (magnitudes result in borrow)
            large_c = HighPrecisionInt(BigInt(2)^60 + 50)
            large_d = HighPrecisionInt(BigInt(2)^60 + 10)
            @test BigInt(large_c - large_d) == 40

            # Very large multiplication
            super_large1 = HighPrecisionInt(BigInt(10)^40 + 1)
            super_large2 = HighPrecisionInt(BigInt(10)^30 + 5)
            @test BigInt(super_large1 * super_large2) == (BigInt(10)^40 + 1) * (BigInt(10)^30 + 5)
        end
    end

    # 3. Unary and Comparison Operations
    @testset "Unary and Comparison Operations" begin
        val1 = HighPrecisionInt(123)
        val2 = HighPrecisionInt(456)
        val3 = HighPrecisionInt(-123)
        val4 = HighPrecisionInt(-456)
        val0 = HighPrecisionInt(0)

        # abs
        @test BigInt(abs(val1)) == 123
        @test BigInt(abs(val3)) == 123
        @test BigInt(abs(val0)) == 0

        # Unary negation
        @test BigInt(-val1) == -123
        @test BigInt(-val3) == 123
        @test BigInt(-val0) == 0

        # isequal (==)
        @test (HighPrecisionInt(10) == HighPrecisionInt(10)) == true
        @test (HighPrecisionInt(10) == HighPrecisionInt(-10)) == false
        @test (HighPrecisionInt(0) == HighPrecisionInt(0)) == true
        @test (HighPrecisionInt(10) == HighPrecisionInt(11)) == false

        # isless (<)
        @test (HighPrecisionInt(10) < HighPrecisionInt(20)) == true
        @test (HighPrecisionInt(20) < HighPrecisionInt(10)) == false
        @test (HighPrecisionInt(-20) < HighPrecisionInt(-10)) == true
        @test (HighPrecisionInt(-10) < HighPrecisionInt(-20)) == false
        @test (HighPrecisionInt(-5) < HighPrecisionInt(5)) == true
        @test (HighPrecisionInt(5) < HighPrecisionInt(-5)) == false
        @test (HighPrecisionInt(0) < HighPrecisionInt(1)) == true
        @test (HighPrecisionInt(-1) < HighPrecisionInt(0)) == true
        @test (HighPrecisionInt(10) < HighPrecisionInt(10)) == false
    end

    # 4. normalize! behavior - Corrected and expanded test cases
    @testset "normalize! behavior" begin
        # Test a coefficient that overflows its 'slot' and carries over
        # Input: [HIGH_PRECISION_BASE + 5] which is [2^32 + 5].
        # Expected after normalize: [5, 1] because 2^32 + 5 = 5 * (2^32)^0 + 1 * (2^32)^1
        hpi_overflow_coeff = HighPrecisionInt([HighPrecisionArithmetic.HIGH_PRECISION_BASE + UInt64(0x05)]) # Cast to UInt64
        @test BigInt(hpi_overflow_coeff) == BigInt(HighPrecisionArithmetic.HIGH_PRECISION_BASE) + 5
        @test hpi_overflow_coeff.coeffs == [0x00000005, 0x00000001]

        # Test with a value that requires a carry to a new, higher coefficient
        # Input: [typemax(UInt64)] which is [2^64 - 1].
        # In base 2^32, this is [2^32-1, 2^32-1].
        hpi_large_carry = HighPrecisionInt([typemax(UInt64)])
        @test BigInt(hpi_large_carry) == typemax(UInt64)
        @test hpi_large_carry.coeffs == [0xffffffff, 0xffffffff]
        
        # Test a scenario where trailing zeros are explicitly provided and should be removed
        # Input: [1, 0, 0, 0]
        # Expected: [1]
        hpi_trailing_zero = HighPrecisionInt([UInt64(0x01), UInt64(0x00), UInt64(0x00), UInt64(0x00)]) # Cast all to UInt64
        @test BigInt(hpi_trailing_zero) == 1
        @test hpi_trailing_zero.coeffs == [0x00000001]

        # Test an explicitly denormalized input where normalize! should collapse it to base 1
        # This represents 1 * (2^32)^0 + 0 * (2^32)^1 + 0 * (2^32)^2 which is just 1.
        # Expected: [1]
        hpi_denormalized_input = HighPrecisionInt([UInt64(0x00000001), UInt64(0x00000000), UInt64(0x00000000)], Int8(1)) # Cast all to UInt64
        @test BigInt(hpi_denormalized_input) == 1
        @test hpi_denormalized_input.coeffs == [0x00000001]

        # Test a case where the value is zero but input coeffs are not just [0x00] initially
        # The inner constructor will call normalize!, which should set sign to 0 and coeffs to [0x00]
        hpi_zero_coeffs_input = HighPrecisionInt([UInt64(0x00), UInt64(0x00), UInt64(0x00)], Int8(1)) # Cast all to UInt64
        @test BigInt(hpi_zero_coeffs_input) == 0
        @test hpi_zero_coeffs_input.sign == 0
        @test hpi_zero_coeffs_input.coeffs == [0x00000000]

        # Test a case with an initial zero coefficient that is part of the number's magnitude
        # This represents 0 * (2^32)^0 + 1 * (2^32)^1 = 2^32.
        # Expected: [0, 1]
        hpi_initial_zero = HighPrecisionInt([UInt64(0x00000000), UInt64(0x00000001)]) # Cast all to UInt64
        @test BigInt(hpi_initial_zero) == BigInt(HighPrecisionArithmetic.HIGH_PRECISION_BASE)
        @test hpi_initial_zero.coeffs == [0x00000000, 0x00000001]

        # Test another case requiring carry propagation across multiple coefficients
        # Value: 1 * 2^32^0 + (2^32 + 1) * 2^32^1 + (2^32 + 2) * 2^32^2
        # = 1 + (2^32+1)*2^32 + (2^32+2)*2^64
        # Input coeffs `[1, 2^32+1, 2^32+2]`
        # First coeff: 1 (no change)
        # Second coeff: 2^32+1 -> 1, carry 1
        # Third coeff: 2^32+2 + carry(1) -> 2^32+3 -> 3, carry 1
        # New coeff: 1
        # Expected normalized coeffs: [1, 1, 3, 1]
        raw_coeffs_complex = [UInt64(0x00000001), HighPrecisionArithmetic.HIGH_PRECISION_BASE + UInt64(0x01), HighPrecisionArithmetic.HIGH_PRECISION_BASE + UInt64(0x02)] # Cast all to UInt64
        hpi_complex = HighPrecisionInt(raw_coeffs_complex)
        expected_bigint_complex = BigInt(1) + (BigInt(HighPrecisionArithmetic.HIGH_PRECISION_BASE)+1)*BigInt(HighPrecisionArithmetic.HIGH_PRECISION_BASE) + (BigInt(HighPrecisionArithmetic.HIGH_PRECISION_BASE)+2)*BigInt(HighPrecisionArithmetic.HIGH_PRECISION_BASE)^2
        @test BigInt(hpi_complex) == expected_bigint_complex
        @test hpi_complex.coeffs == [0x00000001, 0x00000001, 0x00000003, 0x00000001]
    end
end
