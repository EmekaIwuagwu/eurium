module eurium_addr::eurium {
    use aptos_framework::fungible_asset::{Self, MintRef, BurnRef, TransferRef, Metadata, FungibleAsset};
    use aptos_framework::object::{Self, Object, ExtendRef};
    use aptos_framework::primary_fungible_store;
    use std::option;
    use std::string::{Self, String};
    use std::signer;
    use std::event;

    /// Roles and errors
    const ENOT_OWNER: u64 = 1;
    const EPAUSED: u64 = 2;
    const EMAX_SUPPLY_EXCEEDED: u64 = 3;

    struct EuriumInfo has key {
        mint_ref: MintRef,
        burn_ref: BurnRef,
        transfer_ref: TransferRef,
        extend_ref: ExtendRef,
        is_paused: bool,
    }

    struct RedemptionRequest has key, store {
        amount: u64,
        redemption_id: String,
        completed: bool,
    }

    #[event]
    struct MintEvent has drop, store {
        to: address,
        amount: u64,
    }

    #[event]
    struct BurnEvent has drop, store {
        from: address,
        amount: u64,
    }

    #[event]
    struct PauseEvent has drop, store {
        is_paused: bool,
    }

    /// Initialize the Eurium stablecoin as a Fungible Asset
    public entry fun initialize(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        // Create the metadata object
        let constructor_ref = &object::create_named_object(admin, b"Eurium");
        primary_fungible_asset::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            string::utf8(b"Eurium"),
            string::utf8(b"EUI"),
            8,
            string::utf8(b"https://eurium.io/favicon.ico"),
            string::utf8(b"https://eurium.io"),
        );

        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);

        move_to(admin, EuriumInfo {
            mint_ref,
            burn_ref,
            transfer_ref,
            extend_ref,
            is_paused: false,
        });
    }

    /// Mint new EUI tokens
    public entry fun mint(admin: &signer, to: address, amount: u64) acquires EuriumInfo {
        let info = borrow_global<EuriumInfo>(signer::address_of(admin));
        assert!(!info.is_paused, EPAUSED);
        
        let fa = fungible_asset::mint(&info.mint_ref, amount);
        primary_fungible_store::deposit(to, fa);

        event::emit(MintEvent { to, amount });
    }

    /// Burn EUI tokens
    public entry fun burn(admin: &signer, from: address, amount: u64) acquires EuriumInfo {
        let info = borrow_global<EuriumInfo>(signer::address_of(admin));
        
        let from_store = primary_fungible_store::primary_store(from, get_metadata());
        fungible_asset::burn_from(&info.burn_ref, from_store, amount);

        event::emit(BurnEvent { from, amount });
    }

    /// Pause/Unpause transfers
    public entry fun set_pause(admin: &signer, paused: bool) acquires EuriumInfo {
        let info = borrow_global_mut<EuriumInfo>(signer::address_of(admin));
        info.is_paused = paused;
        event::emit(PauseEvent { is_paused: paused });
    }

    #[view]
    public fun get_metadata(): Object<Metadata> {
        let metadata_address = object::create_object_address(&@eurium_addr, b"Eurium");
        object::address_to_object<Metadata>(metadata_address)
    }
}
