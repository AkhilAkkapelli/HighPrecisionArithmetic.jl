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

    # 4. normalize! functionality (internal checks, but can be tested via behavior)
    @testset "normalize! behavior" begin
        # Test large carry
        hpi_raw_coeffs = HighPrecisionArithmetic.HighPrecisionInt([HighPrecisionArithmetic.HIGH_PRECISION_BASE + 1, 0x01]) # Should normalize to [0x01, 0x02]
        @test BigInt(hpi_raw_coeffs) == BigInt(HighPrecisionArithmetic.HIGH_PRECISION_BASE) * 2 + 1 # Should be base*1 + 1 + base*1 = 2*base + 1
        # The constructor calls normalize!, so we check the result
        @test hpi_raw_coeffs.coeffs[1] == 0x01
        @test hpi_raw_coeffs.coeffs[2] == 0x02

        # Test zeros at end
        hpi_trailing_zeros = HighPrecisionArithmetic.HighPrecisionInt([0x01, 0x00, 0x00])
        @test BigInt(hpi_trailing_zeros) == 1
        @test hpi_trailing_zeros.coeffs == [0x01]

        # Test all zeros
        hpi_all_zeros = HighPrecisionArithmetic.HighPrecisionInt([0x00, 0x00])
        @test BigInt(hpi_all_zeros) == 0
        @test hpi_all_zeros.sign == 0
        @test hpi_all_zeros.coeffs == [0x00]
    end
end
