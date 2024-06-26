// Copyright (c) MangoNet Labs Ltd.
// SPDX-License-Identifier: Apache-2.0

module tto::M2 {
    use mgo::object::{Self, UID};
    use mgo::tx_context::{Self, TxContext};
    use mgo::transfer::{Self, Receiving};
    use mgo::dynamic_field as df;

    struct A has key, store {
        id: UID,
    }

    struct B has key, store {
        id: UID,
    }

    struct C has key {
        id: UID, 
        wrapped: B,
    }

    public fun start(ctx: &mut TxContext) {
        let a = A { id: object::new(ctx) };
        let a_address = object::id_address(&a);
        let b = B { id: object::new(ctx) };
        let c = C { id: object::new(ctx), wrapped: b };
        transfer::public_transfer(a, tx_context::sender(ctx));
        transfer::transfer(c, a_address);
    }

    public entry fun unwrap_receiver(parent: &mut A, x: Receiving<C>) {
        let C { id, wrapped } = transfer::receive(&mut parent.id, x);
        transfer::public_transfer(wrapped, @0x0);
        object::delete(id);
    }

    public entry fun unwrap_deleter(parent: &mut A, x: Receiving<C>) {
        let C { id, wrapped: B { id: idb } } = transfer::receive(&mut parent.id, x);
        object::delete(id);
        object::delete(idb);
    }

    public entry fun unwrap_add_dyn(parent: &mut A, x: Receiving<C>) {
        let C { id, wrapped } = transfer::receive(&mut parent.id, x);
        object::delete(id);
        df::add(&mut parent.id, 0, wrapped);
    }
}

