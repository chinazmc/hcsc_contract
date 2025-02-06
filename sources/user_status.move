
module hcsc_contract::user_status {

    use std::string::{String,utf8};
    use sui::clock::Clock;
    use sui::event;
    public struct UserStatus has key,store {
        id:UID,
        user_name:String,
        user_address:address,
        cur_status: String,
        from_time:u64,
    }
    public struct UserStatusEvent has copy, drop {
        from: address,
        cur_status: String,
        action_type: String,
    }
    public entry fun create_user_status(user_name: String,user_address:address,cur_status: String,_clock: &Clock,ctx: &mut TxContext) {
        let status = UserStatus {
            id:object::new(ctx),
            user_name: user_name,
            user_address:user_address,
            cur_status:cur_status,
            from_time:_clock.timestamp_ms()/1000,
        };
        event::emit(UserStatusEvent {
            from: user_address,
            cur_status: cur_status,
            action_type: utf8(b"create"),
        });
        transfer::public_transfer(status,ctx.sender())
    }

    public entry fun update_user_status(user_status: &mut UserStatus,cur_status: String,_clock: &Clock) {
        user_status.cur_status = cur_status;
        user_status.from_time = _clock.timestamp_ms()/1000;
        event::emit(UserStatusEvent {
            from: user_status.user_address,
            cur_status: cur_status,
            action_type: utf8(b"update"),
        })
    }
}