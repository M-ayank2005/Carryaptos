module TransportContractAddress::TransportContract {
    use std::signer;
    use std::vector;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use aptos_framework::account;

    struct Order has store, drop, copy {
        carrier: address,
        sender: address,
        goods_value: u64,
        service_fee: u64,
        status: u8,
        creation_time: u64,
    }

    struct OrdersStore has key {
        orders: vector<Order>,
        events: event::EventHandle<OrderEvent>,
    }

    struct OrderEvent has drop, store {
        carrier: address,
        sender: address,
        goods_value: u64,
        service_fee: u64,
        status: u8,
        timestamp: u64,
    }

    const CREATED: u8 = 0;
    const AGREED: u8 = 1;
    const LOCKED: u8 = 2;
    const DELIVERED: u8 = 3;

    const E_NOT_INITIALIZED: u64 = 1;
    const E_INVALID_STATUS: u64 = 2;
    const E_UNAUTHORIZED: u64 = 3;
    const E_INSUFFICIENT_BALANCE: u64 = 4;

    public entry fun init(account: &signer) {
        let account_addr = signer::address_of(account);
        assert!(!exists<OrdersStore>(account_addr), E_NOT_INITIALIZED);
        move_to(account, OrdersStore {
            orders: vector::empty(),
            events: account::new_event_handle<OrderEvent>(account),
        });
    }

    public entry fun create_order(
        carrier: &signer,
        sender: address,
        goods_value: u64,
        service_fee: u64
    ) acquires OrdersStore {
        let carrier_addr = signer::address_of(carrier);
        let orders_store = borrow_global_mut<OrdersStore>(carrier_addr);
        let order = Order {
            carrier: carrier_addr,
            sender,
            goods_value,
            service_fee,
            status: CREATED,
            creation_time: timestamp::now_seconds(),
        };
        vector::push_back(&mut orders_store.orders, order);
        emit_event(carrier_addr, &mut orders_store.events, order, CREATED);
    }

    public entry fun agree(account: &signer, carrier: address, index: u64) acquires OrdersStore {
        let orders_store = borrow_global_mut<OrdersStore>(carrier);
        let order = vector::borrow_mut(&mut orders_store.orders, index);
        let account_addr = signer::address_of(account);
        assert!(order.status == CREATED, E_INVALID_STATUS);
        assert!(account_addr == order.carrier || account_addr == order.sender, E_UNAUTHORIZED);
        
        if (account_addr == order.sender) {
            assert!(coin::balance<AptosCoin>(account_addr) >= order.service_fee, E_INSUFFICIENT_BALANCE);
            coin::transfer<AptosCoin>(account, carrier, order.service_fee);
        };

        order.status = AGREED;
        emit_event(carrier, &mut orders_store.events, *order, AGREED);
    }

    public entry fun lock_goods_value(carrier: &signer, index: u64) acquires OrdersStore {
        let carrier_addr = signer::address_of(carrier);
        let orders_store = borrow_global_mut<OrdersStore>(carrier_addr);
        let order = vector::borrow_mut(&mut orders_store.orders, index);
        assert!(order.status == AGREED, E_INVALID_STATUS);
        assert!(order.carrier == carrier_addr, E_UNAUTHORIZED);
        assert!(coin::balance<AptosCoin>(carrier_addr) >= order.goods_value, E_INSUFFICIENT_BALANCE);

        coin::transfer<AptosCoin>(carrier, @TransportContractAddress, order.goods_value);
        order.status = LOCKED;
        emit_event(carrier_addr, &mut orders_store.events, *order, LOCKED);
    }

    public entry fun confirm_delivery(sender: &signer, carrier: address, index: u64) acquires OrdersStore {
        let orders_store = borrow_global_mut<OrdersStore>(carrier);
        let order = vector::borrow_mut(&mut orders_store.orders, index);
        assert!(order.status == LOCKED, E_INVALID_STATUS);
        assert!(order.sender == signer::address_of(sender), E_UNAUTHORIZED);

        let total_amount = order.goods_value + order.service_fee;
        coin::transfer<AptosCoin>(sender, carrier, total_amount);
        
        order.status = DELIVERED;
        emit_event(carrier, &mut orders_store.events, *order, DELIVERED);
        vector::remove(&mut orders_store.orders, index);
    }

    fun emit_event(carrier: address, event_handle: &mut event::EventHandle<OrderEvent>, order: Order, status: u8) {
        event::emit_event(event_handle, OrderEvent {
            carrier: order.carrier,
            sender: order.sender,
            goods_value: order.goods_value,
            service_fee: order.service_fee,
            status,
            timestamp: timestamp::now_seconds(),
        });
    }

    #[view]
    public fun get_order_details(carrier: address, index: u64): (address, address, u64, u64, u8, u64) acquires OrdersStore {
        let orders_store = borrow_global<OrdersStore>(carrier);
        let order = vector::borrow(&orders_store.orders, index);
        (
            order.carrier,
            order.sender,
            order.goods_value,
            order.service_fee,
            order.status,
            order.creation_time
        )
    }
}