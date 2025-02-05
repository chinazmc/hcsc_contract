/*
/// Module: hcsc_contract
module hcsc_contract::hcsc_contract;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module hcsc_contract::hcsc_contract {
    use sui::clock::Clock;
    use std::string::{String,utf8};
    use sui::event;
    use sui::vec_set;

    #[test_only]
    use sui::test_scenario;

    const EInvalidBlob: u64 = 0;
    const EInvalidLen: u64 = 1;

    public struct Health_Center has key,store {
        id: UID,
        user_address_set: vec_set::VecSet<address>,
    }
    public struct HCSC_report has key,store {
        id: UID,
        from: address,
        user_address: address,
        from_time: u64,
        reports: vector<BlobInfo>,
    }
    public struct BlobInfo has store, copy, drop {
        blob_id: String,   // blob id on walrus
        blob_obj: address, // object id on sui chain
    }
    public struct ReportEvent has copy, drop {
        from: address,
        report_id: ID,
        action_type: String,
    }
    // init a empty object
    fun init(ctx: &mut TxContext) {
        let object = Health_Center {
            id: object::new(ctx),
            user_address_set:vec_set::empty<address>()
        };
        transfer::share_object(object);
    }
    public entry fun createReport(center: &mut Health_Center,blob_ids: vector<String>, blob_objs: vector<address>, clock: &Clock,user_address: address, ctx: &mut TxContext) {
        assert!(!vector::is_empty(&blob_ids), EInvalidBlob);
        assert!(vector::length(&blob_ids) == vector::length(&blob_objs), EInvalidLen);

        center.user_address_set.insert(user_address);
        let report_id = object::new(ctx);
        // generate bottle msgs by blob_id and blob_obj
        let blobInfos = createBlobInfos(blob_ids, blob_objs);

        // create drift bottle object
        let report = HCSC_report {
            id: report_id,
            from: user_address,
            user_address: user_address,
            from_time: clock.timestamp_ms()/1000,
            reports: blobInfos,
        };
        event::emit(ReportEvent {
            from: user_address,
            report_id: report.id.to_inner(),
            action_type: utf8(b"create"),
        });

        transfer::public_transfer(report,user_address)
    }
    // Helper function to create BlobInfo vector
    public fun createBlobInfos(blob_ids: vector<String>, blob_objs: vector<address>): vector<BlobInfo> {
        let mut bottle_msg = vector::empty<BlobInfo>();
        let len = blob_ids.length();
        let mut i = 0;
        while( i < len) {
            bottle_msg.insert(
                BlobInfo {
                    blob_id: blob_ids[i],
                    blob_obj:blob_objs[i],
                }, i);
            i = i + 1;
        };
        bottle_msg
    }

    #[test]
    fun test_createHCSC() {
        use std::debug;
        use sui::clock;
        let alice = @0x1;
        let bob = @0x2;
        let mut scenario = test_scenario::begin(alice);
        {
            init(scenario.ctx());
        };
        scenario.next_tx(bob);
        {
            let mut my_clock = clock::create_for_testing(scenario.ctx());
            my_clock.set_for_testing(1000 * 10);

            let mut center = scenario.take_shared<Health_Center>();
            let mut blob_ids = vector::empty<String>();
            let mut blob_objs = vector::empty<address>();

            blob_ids.push_back(utf8(b"5z_AD0YwCFUfoko2NfqiDjqavuEpQ2yrtKmGggG-cRM"));
            // blob_ids.push_back(utf8(b"9b7CO3EVPl9r3HXNC7zbnKOgo8Yprs7U4_jOVLX_huE"));

            blob_objs.push_back(@0x965f3cd3233616565ad858b4d102c80546774552111a5f3d2b67d61b20cf0223);
            // blob_objs.push_back(@0x965f3cd3233616565ad858b4d102c80546774552111a5f3d2b67d61b20cf0223);

            createReport(&mut center, blob_ids, blob_objs,&my_clock ,bob,scenario.ctx());
            test_scenario::return_shared(center);
            my_clock.destroy_for_testing();
        };
        scenario.next_tx(bob);
        {
            let report = test_scenario::take_from_address<HCSC_report>(& scenario,bob);
            debug::print(&report);
            test_scenario::return_to_sender(&scenario,report);
        };
        scenario.end();
    }
}