# PoolMigrator
  Pool Migration
    Pool migration is the process in which we migrate one precreated liquidity pool into new liquidity pool.
    1. After getting LP-address(precreated pair address), we need to get tokens that made LP-address. For this purpose
        we will use IUniswapV2Pair interface and this interface have many useful function like to get tokens(token0, token1) from LPAddress,
        this interface has a function for this purpose named by token0() and token1().
    2. Now we need to get the actuall amount of token0 and token1, for this purpose, we need to remove liquidity and this function returns 
        amount of token0 and amount of token1. why? Because we want to swap amount of token0 and amount of token1. 
    3. Why we need to swap tokens? Because after swap we will get 1 category of token. Each amount of token0 or token1 will be converted into token1 
        or token0. Ultimatly, we will get one kind of token amount. 
    4. Why we need one kind of token amount? Because we have compeletly converted LP tokens(pair tokens) into one kind of token and now we will 
        add liquidity of this token(after swap token0 or token1) with a new token. Means in the start, we had 1 pair of tokens and we convert them 
        into one token and now ultimatly we get 1 kind token.
    5. After swapping, we will add liquidity with after-swaped-token and a new token. So this is a migration of one liquidity into another liquidity.

