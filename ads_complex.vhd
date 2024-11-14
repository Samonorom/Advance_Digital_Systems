---- this file is part of the ADS library

library ads;
use ads.ads_fixed.all;

package ads_complex_pkg is
    -- complex number in rectangular form
    type ads_complex is
    record
        re: ads_sfixed;
        im: ads_sfixed;
    end record ads_complex;

    ---- functions

    -- make a complex number
    function ads_cmplx (
            re, im: in ads_sfixed
        ) return ads_complex;

    -- returns l + r
    function "+" (
            l, r: in ads_complex
        ) return ads_complex;

    -- returns l - r 
    function "-" (
            l, r: in ads_complex
        ) return ads_complex;

    -- returns l * r
    function "*" (
            l, r: in ads_complex
        ) return ads_complex;

    -- returns the complex conjugate of arg
    function conj (
            arg: in ads_complex
        ) return ads_complex;

    -- returns || arg || ** 2
    function abs2 (
            arg: in ads_complex
        ) return ads_sfixed;

    -- returns arg * arg 
    function ads_square (
            arg: in ads_complex
        ) return ads_complex;

    -- constants
--    constant complex_zero: ads_complex :=
--                    ads_cmplx(to_ads_sfixed(0), to_ads_sfixed(0));

end package ads_complex_pkg;

package body ads_complex_pkg is

    -- Create a complex number from real and imaginary parts
    function ads_cmplx (
            re, im: in ads_sfixed
        ) return ads_complex
    is
        variable ret: ads_complex;
    begin
        ret.re := re;
        ret.im := im;
        return ret;
    end function ads_cmplx;

    -- Complex addition
    function "+" (
            l, r: in ads_complex
        ) return ads_complex
    is
        variable ret: ads_complex;
    begin
        ret.re := l.re + r.re;
        ret.im := l.im + r.im;
        return ret;
    end function "+";

    -- Complex subtraction
    function "-" (
            l, r: in ads_complex
        ) return ads_complex
    is
        variable ret: ads_complex;
    begin
        ret.re := l.re - r.re;
        ret.im := l.im - r.im;
        return ret;
    end function "-";

    -- Complex multiplication: (a + bi)(c + di) = (ac - bd) + (ad + bc)i
    function "*" (
            l, r: in ads_complex
        ) return ads_complex
    is
        variable ret: ads_complex;
        variable ac, bd, ad, bc: ads_sfixed;
    begin
        -- Calculate components
        ac := l.re * r.re;
        bd := l.im * r.im;
        ad := l.re * r.im;
        bc := l.im * r.re;

        -- Combine terms
        ret.re := ac - bd;
        ret.im := ad + bc;
        
        return ret;
    end function "*";

    -- Complex conjugate: (a + bi)* = a - bi
    function conj (
            arg: in ads_complex
        ) return ads_complex
    is
        variable ret: ads_complex;
    begin
        ret.re := arg.re;
        ret.im := -arg.im;
        return ret;
    end function conj;

    -- magnitude is Square of absolute value: |a + bi|^2 = a^2 + b^2
    function abs2 (
            arg: in ads_complex
        ) return ads_sfixed
    is
        variable re_sq, im_sq: ads_sfixed;
    begin
        re_sq := arg.re * arg.re;
        im_sq := arg.im * arg.im;
        return re_sq + im_sq;
    end function abs2;

    -- Square of a complex number: (a + bi)^2 = (a^2 - b^2) + (2ab)i
    function ads_square (
            arg: in ads_complex
        ) return ads_complex
    is
        variable ret: ads_complex;
        variable a_sq, b_sq, ab: ads_sfixed;
    begin
        -- Calculate components
        a_sq := arg.re * arg.re;
        b_sq := arg.im * arg.im;
        ab := arg.re * arg.im;

        -- Combine terms
        ret.re := a_sq - b_sq;
        ret.im := ab + ab;  -- 2ab

        return ret;
    end function ads_square;

end package body ads_complex_pkg;