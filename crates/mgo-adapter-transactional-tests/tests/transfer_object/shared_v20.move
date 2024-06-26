// Copyright (c) MangoNet Labs Ltd.
// SPDX-License-Identifier: Apache-2.0

// tests TransferObject should fail for a shared object

//# init --accounts A B --addresses test=0x0 --shared-object-deletion false

//# publish

module test::m {
    use mgo::transfer;
    use mgo::tx_context::TxContext;
    use mgo::object::{Self, UID};

    struct S has key { id: UID }

    public entry fun mint_s(ctx: &mut TxContext) {
        let id = object::new(ctx);
        transfer::share_object(S { id })
    }
}

//# run test::m::mint_s

//# view-object 2,0

//# transfer-object 2,0 --sender A --recipient B

//# view-object 2,0
