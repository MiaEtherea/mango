// Copyright (c) MangoNet Labs Ltd.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
/// Requires a Witness on every transfer. Witness needs to be generated
/// in some way and presented to the `prove` method for the TransferRequest
/// to receive a matching receipt.
///
/// One important use case for this policy is the ability to lock something
/// in the `Kiosk`. When an item is placed into the Kiosk, a `PlacedWitness`
/// struct is created which can be used to prove that the `T` was placed
/// to the `Kiosk`.
module mgo::witness_policy {
    use mgo::transfer_policy::{
        Self as policy,
        TransferPolicy,
        TransferPolicyCap,
        TransferRequest
    };

    /// When a Proof does not find its Rule<Proof>.
    const ERuleNotFound: u64 = 0;

    /// Custom witness-key for the "proof policy".
    struct Rule<phantom Proof: drop> has drop {}

    /// Creator action: adds the Rule.
    /// Requires a "Proof" witness confirmation on every transfer.
    public fun set<T: key + store, Proof: drop>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>
    ) {
        policy::add_rule(Rule<Proof> {}, policy, cap, true);
    }

    /// Buyer action: follow the policy.
    /// Present the required "Proof" instance to get a receipt.
    public fun prove<T: key + store, Proof: drop>(
        _proof: Proof,
        policy: &TransferPolicy<T>,
        request: &mut TransferRequest<T>
    ) {
        assert!(policy::has_rule<T, Rule<Proof>>(policy), ERuleNotFound);
        policy::add_receipt(Rule<Proof> {}, request)
    }
}

#[test_only]
module mgo::witness_policy_tests {
    use mgo::witness_policy;
    use mgo::tx_context::dummy as ctx;
    use mgo::transfer_policy as policy;
    use mgo::transfer_policy_tests::{
        Self as test,
        Asset
    };

    /// Confirmation of an action to use in Policy.
    struct Proof has drop {}

    /// Malicious attempt to use a different proof.
    struct Cheat has drop {}

    #[test]
    fun test_default_flow() {
        let ctx = &mut ctx();
        let (policy, cap) = test::prepare(ctx);

        // set the lock policy and require `Proof` on every transfer.
        witness_policy::set<Asset, Proof>(&mut policy, &cap);

        let request = policy::new_request(test::fresh_id(ctx), 0, test::fresh_id(ctx));

        witness_policy::prove(Proof {}, &policy, &mut request);
        policy::confirm_request(&policy, request);
        test::wrapup(policy, cap, ctx);
    }

    #[test]
    #[expected_failure(abort_code = mgo::transfer_policy::EPolicyNotSatisfied)]
    fun test_no_proof() {
        let ctx = &mut ctx();
        let (policy, cap) = test::prepare(ctx);

        // set the lock policy and require `Proof` on every transfer.
        witness_policy::set<Asset, Proof>(&mut policy, &cap);
        let request = policy::new_request(test::fresh_id(ctx), 0, test::fresh_id(ctx));

        policy::confirm_request(&policy, request);
        test::wrapup(policy, cap, ctx);
    }

    #[test]
    #[expected_failure(abort_code = mgo::witness_policy::ERuleNotFound)]
    fun test_wrong_proof() {
        let ctx = &mut ctx();
        let (policy, cap) = test::prepare(ctx);

        // set the lock policy and require `Proof` on every transfer.
        witness_policy::set<Asset, Proof>(&mut policy, &cap);

        let request = policy::new_request(test::fresh_id(ctx), 0, test::fresh_id(ctx));

        witness_policy::prove(Cheat {}, &policy, &mut request);
        policy::confirm_request(&policy, request);
        test::wrapup(policy, cap, ctx);
    }
}
