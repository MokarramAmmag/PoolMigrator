// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

/*  Pool Migration
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

*/
contract PoolMigration{
    
    address private USDT_PFIN_Pair;   

    // This instance is used To call createPair function.
    IUniswapV2Factory _factory;       

    // This instance is used to call liquidity functions like add or remove etc
    IUniswapV2Router02 private router;

    // We want to interact with precreated LP-address(pair address), so we use IUniswapV2Pair interface
    IUniswapV2Pair private uniPair;
    
    address private firstToken;
    address private secondToken;
    address private USDT;
    uint liquidity;

    // We need to get LP-Address and the 3rd token address which we want to put in addliquidity function.
    constructor(address LPPairAddress, address _TPFIN, address _USDT) {   
        // UniswapV2Router02 (Interface implementation) is deployed at 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D on
        // the Ethereum mainnet as well as testnet 
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniPair = IUniswapV2Pair(LPPairAddress);

        // An interface needs its implementation in its argument. so we put implementation of IUniswapV2Factory by router.factory()
        _factory = IUniswapV2Factory(router.factory());

        secondToken = _TPFIN;
        USDT_PFIN_Pair = _factory.createPair(_TPFIN, _USDT);
    }

    uint tempUSDT; uint tempfirstToken; uint tempTotalUSDT;

    function migrate(address _LPAddress, uint256 liquidity, address to) public {
        uint256 totalUSDT;
        uint256 secondTokenAmount;
        // to make it sure that USDT is the actuall USDT address
        if(uniPair.token0() == USDT){
            USDT = uniPair.token0();
            firstToken = uniPair.token1();
        }
        else{
            USDT = uniPair.token1();
            firstToken = uniPair.token0();
        }
        
        IUniswapV2Pair(_LPAddress).transferFrom(msg.sender,address(this),liquidity);
        IUniswapV2Pair(_LPAddress).approve(address(router),liquidity);
        (uint256 amountUSDT, uint256 fristTokenAmount) = router.removeLiquidity(USDT, firstToken, liquidity, 0, 0, address(this), block.timestamp);
        tempUSDT = amountUSDT; tempfirstToken = fristTokenAmount;
        require(fristTokenAmount > 0, "First token amount must be greater than zero");
        swap(firstToken, USDT, fristTokenAmount);
        totalUSDT = IERC20(USDT).balanceOf(address(this));
        require(totalUSDT>0, "There must be some amount after swapping.");
        tempTotalUSDT = secondTokenAmount = totalUSDT;
        AddLiquidity(secondToken, USDT, to, totalUSDT, secondTokenAmount);
    }
    function getRecords() public view returns(uint tempUSDT, uint tempFirstToken, uint tempTotalUSDT){
        return (tempUSDT, tempfirstToken, tempTotalUSDT);
    }

    function swap(address _TFIN, address _USDT, uint256 _amountIn) private{
        IERC20(_TFIN).approve(address(router), _amountIn);
        address[] memory path;
        path = new address[](2);
        path[0] = _TFIN;
        path[1] = _USDT;
        
        router.swapExactTokensForTokens(_amountIn, 0, path,  address(this), block.timestamp);
        //uint256 totalAmount = ERC20(tokenA).balanceOf(address(this));
    }

    function AddLiquidity(address _TPFIN, address _USDT, address to, uint256 _USDTAmount, uint256 _TPFINAmount) private{         
        IERC20(_TPFIN).transferFrom(msg.sender, address(this), _TPFINAmount); 
        IERC20(_TPFIN).approve(address(router), _TPFINAmount); 
        //IERC20(_USDT).transferFrom(msg.sender, address(this), _USDTAmount);
        IERC20(_USDT).approve(address(router), _USDTAmount); 
        (,,liquidity)=router.addLiquidity(_USDT, _TPFIN, _USDTAmount, _TPFINAmount ,0 ,0 ,to, block.timestamp);
    }

    function showLiquidity() public view returns(uint){
        return liquidity;
    }

    function getContractBalance(address Token) public view returns(uint)  {
        return IERC20(USDT).balanceOf(address(this));
    }
    function getUserBalance(address Token) public view returns(uint)  {
        return IERC20(USDT).balanceOf(msg.sender);
    }

    receive() external payable {
    } 
    // function getTokenATokenB() public view returns(address, address){
    //     return(uniPair.token0(), uniPair.token1());
    // }


}
