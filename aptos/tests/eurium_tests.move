#[test_only]
module eurium_addr::eurium_tests {
    use aptos_framework::account;
    use aptos_framework::fungible_asset;
    use aptos_framework::primary_fungible_store;
    use eurium_addr::eurium;
    use std::signer;

    #[test(admin = @eurium_addr)]
    fun test_initialize_and_mint(admin: signer) {
        account::create_account_for_test(signer::address_of(&admin));
        eurium::initialize(&admin);
        
        let user_addr = @0x123;
        account::create_account_for_test(user_addr);
        
        eurium::mint(&admin, user_addr, 1000);
        
        let metadata = eurium::get_metadata();
        assert!(primary_fungible_store::balance(user_addr, metadata) == 1000, 1);
    }
}
