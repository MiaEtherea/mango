// Copyright (c) MangoNet Labs Ltd.
// SPDX-License-Identifier: Apache-2.0

#[allow(unused_field)]
module b::m {
    use a::m::T2 as M;
    use a::n::T0 as N;

    struct T0 {
        m: M,
        n: N,
    }
}
