module Amm_Dex::coin_factory {
    use std::signer;
    use std::string;
    use std::string::String;
    use std::vector;
    use aptos_std::type_info;
    use aptos_framework::aptos_account;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};
    use aptos_framework::object;
    use aptos_framework::object::ExtendRef;

    ////////////////////
    // Constants ///
    ////////////////////
    const SEED:vector<u8> = b"create_coin";

    //////////////////
    /// Structs ////
    //////////////////
    struct CoinCapabilities<phantom CoinType> has key {
        burn_cap: BurnCapability<CoinType>,
        freeze_cap: FreezeCapability<CoinType>,
        mint_cap: MintCapability<CoinType>,
    }

    struct Coin has key {
        extend_ref: ExtendRef,
        registered_coins:vector<String>,
    }

    ////////////////
    /// Errors ///
    ///////////////
    const ENOT_COIN_OWNER: u64 = 1;
    const ERR_COIN_ALREADY_REGISTERED: u64 = 2;
    const ERR_NOT_COIN_SIGNER: u64 = 3;

    /// Initialize a new coin type
    fun init_module(
        admin: &signer,
    ) {
        // Store the capabilities
        let signer_object = object::create_named_object(admin, SEED);
        let signer_extender = object::generate_extend_ref(&signer_object);
        move_to(admin,Coin{
            extend_ref: signer_extender,
            registered_coins: vector::empty()
        })
    }

    public entry fun init_coin<CoinType>(coin_signer: &signer, name:vector<u8>, symbol:vector<u8>, decimals:u8, monitor_supply:bool) acquires Coin {
        assert!(!is_registered<CoinType>(),ERR_COIN_ALREADY_REGISTERED);
        assert!(signer::address_of(coin_signer) == type_info :: account_address(&type_info::type_of<CoinType>()),ERR_NOT_COIN_SIGNER );

        let (burn_cap,freeze_cap, mint_cap) = coin::initialize<CoinType>(
            coin_signer,
            string::utf8(name),
            string::utf8(symbol),
            decimals,
            monitor_supply
        );

        let signer = get_resource_signer();
        move_to(&signer, CoinCapabilities<CoinType>{
            burn_cap,
            freeze_cap,
            mint_cap,
        });

        vector::push_back(&mut borrow_global_mut<Coin>(get_resource_address()).registered_coins, type_info::type_name<CoinType>());
        coin::register<CoinType>(&signer)
    }

    public entry fun mint_to<CoinType>(to:address, amount:u64) acquires CoinCapabilities {
        assert!(!is_registered<CoinType>(),ERR_COIN_ALREADY_REGISTERED);
         aptos_account::deposit_coins<CoinType>(to, coin::mint(amount,&borrow_global<CoinCapabilities<CoinType>>(get_resource_address()).mint_cap))
    }

    /////////////////////////
    /// View function ///
    /////////////////////////
    #[view]
    public fun is_registered<CoinType>() :  bool {
        exists<CoinCapabilities<CoinType>>(get_resource_address())
    }

    /////////////////////////////
    /// Helper functions ///
    /////////////////////////////
    fun get_resource_address() : address{
        @Amm_Dex
    }

    fun get_resource_signer() : signer acquires Coin {
        let signer_object = borrow_global<Coin>(get_resource_address());
        object::generate_signer_for_extending(&signer_object.extend_ref)
    }
}