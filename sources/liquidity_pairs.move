
module Amm_Dex::liquidity_pairs {
    // create pair
    // swap
    // price feed

    use std::string;
    use std::string::String;
    use std::vector;
    use aptos_std::math128;
    use aptos_framework::object;
    use aptos_framework::object::ExtendRef;

    //////////////////
    /// ERRORS ///
    //////////////////
    const ELIQUIDITY_PAIR_SWAP_AMOUNTOUT_INSIGNIFICANT: u64 = 0;
    const INITIAL_VIRTUAL_APT_LIQUIDITY: u128 = 10_000_000_000; // 100 APT


    /////////////////
    /// Structs ///
    /// /////////////
    struct Pairs has key{
        signer_extender: ExtendRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct LiquidityPair has store,key {
        extend_ref: ExtendRef,
        token_reserves: u128,
        apt_reserves: u128,
    }

    ////////////////////
    /// Constant ///
    ////////////////////
    const SEED:vector<u8> = b"LiquidityPairs";

    //////////////////////
    /// Init function///
    //////////////////////
    fun init_module(admin:&signer){
        let liquidityPairRef = object::generate_extend_ref(&object::create_named_object(admin,SEED));
        move_to(admin,Pairs{
            signer_extender:liquidityPairRef
        })
    }

    ///////////////////////////
    /// entry functions ///
    ///////////////////////////
    public entry fun createLiquidityPairs(signer:&signer, name: String, symbol: String ) acquires Pairs {
        let pairs = borrow_global<Pairs>(@Amm_Dex);
        let pairs_signer = object::generate_signer_for_extending(&pairs.signer_extender);

        let token_key_seed = *string::bytes(&name);
        vector::append(&mut token_key_seed, b"-");
        vector::append(&mut token_key_seed, *string::bytes(&symbol));

        let liquidity_pair_object = object::create_named_object(&pairs_signer, token_key_seed);
        let liquidity_pair_signer = object::generate_signer(&liquidity_pair_object);
        let liquidity_pair_extend_ref = object::generate_extend_ref(&liquidity_pair_object);



        // let liquidity_pair_ref = object::generate_extend_ref(&object::create_named_object(signer,SEED));
        // move_to(signer,LiquidityPair{
        //     extend_ref:liquidity_pair_ref,
        //     token_reserves:token0_reserves,
        //     apt_reserves:token1_reserves
        // });
    }

    //////////////////////
    /// View functions ///
    //////////////////////
    #[view]
    public fun get_amount_out(token_reserves:u128, apt_reserves:u128, amount_in:u128, swap_to_apt:bool):(u128,u128,u128,u128){
        if(swap_to_apt){
            let divisor = token_reserves + amount_in;

            // dy = y * dx / (x + dx)
            let apt_gained = math128::mul_div(apt_reserves, amount_in ,divisor);
            let token_reserves_update = token_reserves + amount_in;
            let apt_reserves_update = apt_reserves - apt_gained;
            assert!(apt_reserves_update >= 0, ELIQUIDITY_PAIR_SWAP_AMOUNTOUT_INSIGNIFICANT);
            (amount_in,apt_gained,token_reserves_update,apt_reserves_update)
        }
        else{
            let divisor = apt_reserves + amount_in;

            // dx = x * dy / (y + dy)
            let token_gained = math128::mul_div(token_reserves, amount_in ,divisor);
            let apt_reserves_update = apt_reserves + amount_in;
            let token_reserves_update = token_reserves - token_gained;
            assert!(token_reserves_update >= 0, ELIQUIDITY_PAIR_SWAP_AMOUNTOUT_INSIGNIFICANT);
            (amount_in,token_gained,token_reserves_update,apt_reserves_update)
        }
    }


}