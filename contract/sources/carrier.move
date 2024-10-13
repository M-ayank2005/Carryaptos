module TransportContract::TransportContractAddress {
    use std::signer;
    use std::vector;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;

    /// Represents an order for transporting goods.
    struct Order has store {
        carrier: address,
        sender: address,
        goods_value: u64,
        service_fee: u64,
        carrier_agreed: bool,
        sender_agreed: bool,
        delivery_confirmed: bool,
        creation_time: u64,
        completion_time: u64,
    }

    /// Stores all active orders.
    struct OrdersStore has key {
        orders: vector<Order>,
        order_created_events: EventHandle<OrderCreatedEvent>,
        order_completed_events: EventHandle<OrderCompletedEvent>,
    }

    /// Event emitted when a new order is created.
    struct OrderCreatedEvent has drop, store {
        carrier: address,
        sender: address,
        goods_value: u64,
        service_fee: u64,
        creation_time: u64,
    }

    /// Event emitted when an order is completed.
    struct OrderCompletedEvent has drop, store {
        carrier: address,
        sender: address,
        goods_value: u64,
        service_fee: u64,
        creation_time: u64,
        completion_time: u64,
    }

    const E_NOT_INITIALIZED: u64 = 1;
    const E_ALREADY_INITIALIZED: u64 = 2;
    const E_NOT_CARRIER: u64 = 3;
    const E_NOT_SENDER: u64 = 4;
    const E_NOT_AGREED: u64 = 5;
    const E_ALREADY_CONFIRMED: u64 = 6;
    const E_NOT_CONFIRMED: u64 = 7;
    const E_INSUFFICIENT_BALANCE: u64 = 8;

    /// Initializes the contract by creating an empty OrdersStore resource.
    public entry fun init(account: &signer) {
        let account_addr = signer::address_of(account);
        assert!(!exists<OrdersStore>(account_addr), E_ALREADY_INITIALIZED);
        
        move_to(account, OrdersStore {
            orders: vector::empty<Order>(),
            order_created_events: account::new_event_handle<OrderCreatedEvent>(account),
            order_completed_events: account::new_event_handle<OrderCompletedEvent>(account),
        });
    }

    /// Create a new order where the carrier proposes transporting goods.
    public entry fun create_order(
        carrier: &signer,
        sender: address,
        goods_value: u64,
        service_fee: u64
    ) acquires OrdersStore {
        let carrier_address = signer::address_of(carrier);
        assert!(exists<OrdersStore>(carrier_address), E_NOT_INITIALIZED);

        let order = Order {
            carrier: carrier_address,
            sender,
            goods_value,
            service_fee,
            carrier_agreed: false,
            sender_agreed: false,
            delivery_confirmed: false,
            creation_time: timestamp::now_seconds(),
            completion_time: 0,
        };

        let orders_store = borrow_global_mut<OrdersStore>(carrier_address);
        vector::push_back(&mut orders_store.orders, order);

        event::emit_event(&mut orders_store.order_created_events, OrderCreatedEvent {
            carrier: carrier_address,
            sender,
            goods_value,
            service_fee,
            creation_time: order.creation_time,
        });
    }

    /// The carrier agrees to the terms of the order.
    public entry fun carrier_agree(carrier: &signer, index: u64) acquires OrdersStore {
        let carrier_address = signer::address_of(carrier);
        let orders_store = borrow_global_mut<OrdersStore>(carrier_address);
        let order = vector::borrow_mut(&mut orders_store.orders, index);
        
        assert!(order.carrier == carrier_address, E_NOT_CARRIER);
        assert!(!order.carrier_agreed, E_ALREADY_CONFIRMED);
        
        order.carrier_agreed = true;
    }

    /// The sender agrees to the terms of the order and locks the service fee.
    public entry fun sender_agree(sender: &signer, carrier: address, index: u64) acquires OrdersStore {
        let sender_address = signer::address_of(sender);
        let orders_store = borrow_global_mut<OrdersStore>(carrier);
        let order = vector::borrow_mut(&mut orders_store.orders, index);

        assert!(order.sender == sender_address, E_NOT_SENDER);
        assert!(!order.sender_agreed, E_ALREADY_CONFIRMED);
        
        // Check if sender has enough balance
        assert!(coin::balance<AptosCoin>(sender_address) >= order.service_fee, E_INSUFFICIENT_BALANCE);

        // Lock the service fee in the contract
        let service_fee_coin = coin::withdraw<AptosCoin>(sender, order.service_fee);
        coin::deposit(carrier, service_fee_coin);

        order.sender_agreed = true;
    }

    /// The carrier locks the goods value in the contract once both parties have agreed.
    public entry fun lock_goods_value(carrier: &signer, index: u64) acquires OrdersStore {
        let carrier_address = signer::address_of(carrier);
        let orders_store = borrow_global_mut<OrdersStore>(carrier_address);
        let order = vector::borrow_mut(&mut orders_store.orders, index);
        
        assert!(order.carrier == carrier_address, E_NOT_CARRIER);
        assert!(order.carrier_agreed && order.sender_agreed, E_NOT_AGREED);
        
        // Check if carrier has enough balance
        assert!(coin::balance<AptosCoin>(carrier_address) >= order.goods_value, E_INSUFFICIENT_BALANCE);

        // Lock the goods value in the contract
        let goods_value_coin = coin::withdraw<AptosCoin>(carrier, order.goods_value);
        coin::deposit(carrier_address, goods_value_coin);
    }

    /// Confirm delivery by the sender.
    public entry fun confirm_delivery(sender: &signer, carrier: address, index: u64) acquires OrdersStore {
        let sender_address = signer::address_of(sender);
        let orders_store = borrow_global_mut<OrdersStore>(carrier);
        let order = vector::borrow_mut(&mut orders_store.orders, index);

        assert!(order.sender == sender_address, E_NOT_SENDER);
        assert!(order.carrier_agreed && order.sender_agreed, E_NOT_AGREED);
        assert!(!order.delivery_confirmed, E_ALREADY_CONFIRMED);

        order.delivery_confirmed = true;
        order.completion_time = timestamp::now_seconds();
    }

    /// Finalize the order and transfer all funds back to the carrier.
    public entry fun finalize_order(carrier: &signer, index: u64) acquires OrdersStore {
        let carrier_address = signer::address_of(carrier);
        let orders_store = borrow_global_mut<OrdersStore>(carrier_address);
        let order = vector::borrow_mut(&mut orders_store.orders, index);
        
        assert!(order.carrier == carrier_address, E_NOT_CARRIER);
        assert!(order.delivery_confirmed, E_NOT_CONFIRMED);

        // Calculate total amount to transfer.
        let total_amount = order.goods_value + order.service_fee;

        // Transfer funds back to the carrier.
        let payment_coin = coin::withdraw<AptosCoin>(carrier, total_amount);
        coin::deposit(carrier_address, payment_coin);

        // Emit completion event
        event::emit_event(&mut orders_store.order_completed_events, OrderCompletedEvent {
            carrier: order.carrier,
            sender: order.sender,
            goods_value: order.goods_value,
            service_fee: order.service_fee,
            creation_time: order.creation_time,
            completion_time: order.completion_time,
        });

        // Remove the order from the list.
        vector::remove(&mut orders_store.orders, index);
    }

    /// Get the details of an order.
    public fun get_order_details(carrier: address, index: u64): (address, address, u64, u64, bool, bool, bool, u64, u64) acquires OrdersStore {
        let orders_store = borrow_global<OrdersStore>(carrier);
        let order = vector::borrow(&orders_store.orders, index);
        
        (
            order.carrier,
            order.sender,
            order.goods_value,
            order.service_fee,
            order.carrier_agreed,
            order.sender_agreed,
            order.delivery_confirmed,
            order.creation_time,
            order.completion_time
        )
    }
}