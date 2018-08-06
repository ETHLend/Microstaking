pragma solidity ^0.4.8;

// https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}




contract KyberReserve {
    address public reserveOwner;
    address public kyberNetwork;
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint  constant PRECISION = (10**18);
    bool public tradeEnabled;

    struct ConversionRate {
        uint rate;
        uint expirationBlock;
    }
    
    mapping(bytes32=>ConversionRate) pairConversionRate;
    

    function KyberReserve( address _kyberNetwork, address _reserveOwner ) {
        kyberNetwork = _kyberNetwork;
        reserveOwner = _reserveOwner;
        tradeEnabled = true;
    }
    
    
    function isPairListed( ERC20 source, ERC20 dest, uint blockNumber ) internal constant returns(bool) {
        ConversionRate memory rateInfo = pairConversionRate[sha3(source,dest)];
        if( rateInfo.rate == 0 ) return false;
        return rateInfo.expirationBlock >= blockNumber;
    }
    
    function getConversionRate( ERC20 source, ERC20 dest, uint blockNumber ) internal constant returns(uint) {
        ConversionRate memory rateInfo = pairConversionRate[sha3(source,dest)];
        if( rateInfo.rate == 0 ) return 0;
        if( rateInfo.expirationBlock < blockNumber ) return 0;
        return rateInfo.rate;
    }
    
    event ErrorReport( address indexed origin, uint error, uint errorInfo );
    event DoTrade( address indexed origin, address source, uint sourceAmount, address destToken, uint destAmount, address destAddress );
    
    function doTrade( ERC20 sourceToken,
                      uint sourceAmount,
                      ERC20 destToken,
                      address destAddress,
                      bool validate ) internal returns(bool) {

        // can skip validation if done at kyber network level        
        if( validate ) {
            if( ! isPairListed( sourceToken, destToken, block.number ) ) {
                // pair is not listed
                ErrorReport( tx.origin, 0x800000001, 0 );
                return false;
                
            }
            if( sourceToken == ETH_TOKEN_ADDRESS ) {
                if( msg.value != sourceAmount ) {
                    // msg.value != sourceAmmount
                    ErrorReport( tx.origin, 0x800000002, msg.value );
                    return false;
                }
            }
            else if( msg.value > 0 ) {
                // msg.value must be 0
                ErrorReport( tx.origin, 0x800000003, msg.value );
                return false;
            }
            else if( sourceToken.allowance(msg.sender, this ) < sourceAmount ) {
                // allowance is not enough
                ErrorReport( tx.origin, 0x800000004, sourceToken.allowance(msg.sender, this ) );
                return false;
            }
        }
        
        uint conversionRate = getConversionRate( sourceToken, destToken, block.number );
        // TODO - safe multiplication
        uint destAmount = (conversionRate * sourceAmount) / PRECISION;

        // sanity check            
        if( destAmount == 0 ) {
            // unexpected error: dest amount is 0
            ErrorReport( tx.origin, 0x800000005, 0 );
            return false;
        }
        
        // check for sufficient balance
        if( destToken == ETH_TOKEN_ADDRESS ) {
            if( this.balance < destAmount ) {
                // insufficient ether balance
                ErrorReport( tx.origin, 0x800000006, destAmount );
                return false;
            }
        }
        else {
            if( destToken.balanceOf(this) < destAmount ) {
                // insufficient token balance
                ErrorReport( tx.origin, 0x800000007, uint(destToken) );
                return false;
            }
        }
        
        // collect source tokens
        if( sourceToken != ETH_TOKEN_ADDRESS ) {
            if( ! sourceToken.transferFrom(msg.sender,this,sourceAmount) ) {
                // transfer from source token failed
                ErrorReport( tx.origin, 0x800000008, uint(sourceToken) );
                return false;
            }
        }
        
        // send dest tokens
        if( destToken == ETH_TOKEN_ADDRESS ) {
            if( ! destAddress.send(destAmount) ) {
                // transfer ether to dest failed
                ErrorReport( tx.origin, 0x800000009, uint(destAddress) );
                return false;
            }
        }
        else {
            if( ! destToken.transfer(destAddress, destAmount) ) {
                // transfer token to dest failed
                ErrorReport( tx.origin, 0x80000000a, uint(destAddress) );
                return false;
            }
        }
        
        DoTrade( tx.origin, sourceToken, sourceAmount, destToken, destAmount, destAddress );        
        
        return true;
    }
    
    function trade( ERC20 sourceToken,
                    uint sourceAmount,
                    ERC20 destToken,
                    address destAddress,
                    bool validate ) payable returns(bool) {

        if( ! tradeEnabled ) {
            // trade is not enabled
            ErrorReport( tx.origin, 0x810000000, 0 );
            if( msg.value > 0 ) {
                if( ! msg.sender.send(msg.value) ) throw;
            }
            return false;
        }

        if( msg.sender != kyberNetwork ) {
            // sender must be kyber network
            ErrorReport( tx.origin, 0x810000001, uint(msg.sender) );
            if( msg.value > 0 ) {
                if( ! msg.sender.send(msg.value) ) throw;
            }
            
            return false;
        }
        
        if( ! doTrade( sourceToken, sourceAmount, destToken, destAddress, validate ) ) {
            // do trade failed
            ErrorReport( tx.origin, 0x810000002, 0 );
            if( msg.value > 0 ) {
                if( ! msg.sender.send(msg.value) ) throw;
            }
            return false;
        }
        
        ErrorReport( tx.origin, 0, 0 );
        return true;
    }
    
    event SetRate( ERC20 source, ERC20 dest, uint rate, uint expiryBlock );
    function setRate( ERC20[] sources, ERC20[] dests, uint[] conversionRates, uint[] expiryBlocks, bool vaildate ) returns(bool) {
        if( msg.sender != reserveOwner ) {
            // sender must be reserve owner
            ErrorReport( tx.origin, 0x820000000, uint(msg.sender) );
            return false;
        }
        
        if( vaildate ) {
            if( ( sources.length != dests.length ) ||
                ( sources.length != conversionRates.length ) ||
                ( sources.length != expiryBlocks.length ) ) {
                // arrays length are not identical
                ErrorReport( tx.origin, 0x820000001, 0 );
                return false;
            }
        }
        
        for( uint i = 0 ; i < sources.length ; i++ ) {
            SetRate( sources[i], dests[i], conversionRates[i], expiryBlocks[i] );
            pairConversionRate[sha3(sources[i],dests[i])] = ConversionRate( conversionRates[i], expiryBlocks[i] );               
        }
        
        ErrorReport( tx.origin, 0, 0 );
        return true;
    }

    event EnableTrade( bool enable );
    function enableTrade( bool enable ) returns(bool){
        if( msg.sender != reserveOwner ) {
            // sender must be reserve owner
            ErrorReport( tx.origin, 0x830000000, uint(msg.sender) );
            return false;
        }
        
        tradeEnabled = enable;
        ErrorReport( tx.origin, 0, 0 );
        EnableTrade( enable );
        
        return true;
    }

    event DepositToken( ERC20 token, uint amount );
    function() payable {
        DepositToken( ETH_TOKEN_ADDRESS, msg.value );        
    }
    function depositEther( ) payable returns(bool) {
        /*
        if( msg.sender != reserveOwner ) {
            // sender must be reserve owner
            ErrorReport( tx.origin, 0x840000000, uint(msg.sender) );
            if( msg.value > 0 ) {
                if( ! msg.sender.send(msg.value) ) throw;
            }
            return false;
        }*/
        
        ErrorReport( tx.origin, 0, 0 );        
        
        DepositToken( ETH_TOKEN_ADDRESS, msg.value );
        return true;
    }
    
    function depositToken( ERC20 token, uint amount ) returns(bool) {
        /*
        if( msg.sender != reserveOwner ) {
            // sender must be reserve owner
            ErrorReport( tx.origin, 0x850000000, uint(msg.sender) );
            return false;
        }*/

        if( token.allowance( msg.sender, this ) < amount ) {
            // allowence is smaller then amount
            ErrorReport( tx.origin, 0x850000001, token.allowance( msg.sender, this ) );
            return false;
        }
        
        if( ! token.transferFrom(msg.sender, this, amount ) ) {
            // transfer from failed
            ErrorReport( tx.origin, 0x850000002, uint(token) );
            return false;
        }
        
        DepositToken( token, amount );
        return true;
    }
    
    
    event Withdraw( ERC20 token, uint amount, address destination );
    function withdraw( ERC20 token, uint amount, address destination ) returns(bool) {
        if( msg.sender != reserveOwner ) {
            // sender must be reserve owner
            ErrorReport( tx.origin, 0x860000000, uint(msg.sender) );
            return false;
        }
        
        if( token == ETH_TOKEN_ADDRESS ) {
            if( ! destination.send(amount) ) throw;
        }
        else if( ! token.transfer(destination,amount) ) {
            // transfer to reserve owner failed
            ErrorReport( tx.origin, 0x860000001, uint(token) );
            return false;
        }
        
        ErrorReport( tx.origin, 0, 0 );
        Withdraw( token, amount, destination );
    }
    
    
    ////////////////////////////////////////////////////////////////////////////
    /// status functions ///////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    
    // returns (rate, block expiration, balance of dest)    
    function getPairInfo( ERC20 source, ERC20 dest ) constant returns(uint rate, uint expBlock, uint balance) {
        ConversionRate memory rateInfo = pairConversionRate[sha3(source,dest)];
        balance = 0;
        if( dest == ETH_TOKEN_ADDRESS ) balance = this.balance;
        else balance = dest.balanceOf(this);
        
        expBlock = rateInfo.expirationBlock;
        rate = rateInfo.rate;
    }
    
    function getBalance( ERC20 token ) constant returns(uint){
        if( token == ETH_TOKEN_ADDRESS ) return this.balance;
        else return token.balanceOf(this);
    }
}





////////////////////////////////////////////////////////////////////////////////////////////////////////

contract KyberNetwork {
    address admin;
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint  constant PRECISION = (10**18);
    uint  constant EPSILON = (1000);
    KyberReserve[] public reserves;
    
    mapping(address=>mapping(bytes32=>bool)) perReserveListedPairs;

    event ErrorReport( address indexed origin, uint error, uint errorInfo );
    
    function KyberNetwork( address _admin ) {
        admin = _admin;
    }
    
    
    struct KyberReservePairInfo {
        uint rate;
        uint reserveBalance;
        KyberReserve reserve;    
    }
    
    function getNumReserves() constant returns(uint){
        return reserves.length;    
    }
    
    function getRate( ERC20 source, ERC20 dest, uint reserveIndex ) constant returns(uint rate, uint expBlock, uint balance){
        (rate,expBlock, balance) = reserves[reserveIndex].getPairInfo(source,dest);
    }
    
    function findBestRate( ERC20 source, ERC20 dest ) internal constant returns(KyberReservePairInfo) {
    
        uint bestRate;
        uint bestReserveBalance = 0;
        uint numReserves = reserves.length;
        
        KyberReservePairInfo memory output;
        KyberReserve bestReserve = KyberReserve(0);
        
        for( uint i = 0 ; i < numReserves ; i++ ) {
            var (rate,expBlock,balance) = reserves[i].getPairInfo(source,dest); 
            /*uint[3] memory info = 
            uint rate = info[0];
            uint expBlock = info[1];
            uint balance = info[2];*/
        
            
            if( (expBlock >= block.number) && (balance > 0) && (rate > bestRate ) ) {
                bestRate = rate;
                bestReserveBalance = balance;
                bestReserve = reserves[i];
            }
        }
        output.rate = bestRate;
        output.reserveBalance = bestReserveBalance;
        output.reserve = bestReserve;
        
        return output;
    }
    
    function doSingleTrade( ERC20 source, uint amount,
                            ERC20 dest, address destAddress,
                            KyberReserve reserve,
                            bool validate ) internal returns(bool) {
                                
        uint callValue = 0;
        if( source == ETH_TOKEN_ADDRESS ) callValue = amount;
        else {
            // take source tokens to this contract
            source.transferFrom(msg.sender, this, amount);
            
            // let reserve use network tokens
            source.approve( reserve, amount);
        }

        if( ! reserve.trade.value(callValue)(source, amount, dest, destAddress, validate ) ) {
            if( source != ETH_TOKEN_ADDRESS ) {
                // reset tokens for reserve
                if( ! source.approve( reserve, 0) ) throw;
                
                // send tokens back to sender
                if( ! source.transfer(msg.sender, amount) ) throw;
            }
            
            return false;
        }
        
        if( source != ETH_TOKEN_ADDRESS ) {
            source.approve( reserve, 0);
        }
                
        return true;
    }
    
    function validateTradeInput( ERC20 source, uint srcAmount ) constant internal returns(bool) {
        if( source != ETH_TOKEN_ADDRESS && msg.value > 0 ) {
            // shouldn't send ether for token exchange
            ErrorReport( tx.origin, 0x85000000, 0 );
            return false;
        }
        else if( source == ETH_TOKEN_ADDRESS && msg.value != srcAmount ) {
            // amount of sent ether is wrong
            ErrorReport( tx.origin, 0x85000001, msg.value );
            return false;
        }
        else if( source != ETH_TOKEN_ADDRESS ) {
            if( source.allowance(msg.sender,this) < srcAmount ) {
                // insufficient allowane
                ErrorReport( tx.origin, 0x85000002, msg.value );
                return false;
            }
        }
        
        return true;
        
    }
    
    event Trade( address indexed sender, ERC20 source, ERC20 dest, uint actualSrcAmount, uint actualDestAmount );
    
    struct ReserveTokenInfo {
        uint rate;
        KyberReserve reserve;
        uint reserveBalance;
    }
    
    struct TradeInfo {
        uint convertedDestAmount;
        uint remainedSourceAmount;
        
        bool tradeFailed;
    }
    
    function trade( ERC20 source, uint srcAmount,
                    ERC20 dest, address destAddress, uint maxDestAmount,
                    uint minConversionRate,
                    bool throwOnFailure ) payable returns(uint) {

        if( ! validateTradeInput( source, srcAmount ) ) {
            // invalid input
            ErrorReport( tx.origin, 0x86000000, 0 );
            if( msg.value > 0 ) {
                if( ! msg.sender.send(msg.value) ) throw;
            }
            if( throwOnFailure ) throw;
            return 0;
        }

        TradeInfo memory tradeInfo = TradeInfo(0,srcAmount,false);
        
        while( (tradeInfo.convertedDestAmount + EPSILON < maxDestAmount) && (tradeInfo.remainedSourceAmount > EPSILON) ) {
            KyberReservePairInfo memory reserveInfo = findBestRate(source,dest);

            if( reserveInfo.rate == 0 || reserveInfo.rate < minConversionRate ) {
                tradeInfo.tradeFailed = true;
                // no more available funds
                ErrorReport( tx.origin, 0x86000001, tradeInfo.remainedSourceAmount );
                break;
            }
            
            uint actualSrcAmount = tradeInfo.remainedSourceAmount;
            // TODO - overflow check
            uint actualDestAmount = (actualSrcAmount * reserveInfo.rate) / PRECISION;
            if( actualDestAmount > reserveInfo.reserveBalance ) {
                actualDestAmount = reserveInfo.reserveBalance;
            }
            if( actualDestAmount + tradeInfo.convertedDestAmount > maxDestAmount ) {
                actualDestAmount = maxDestAmount - tradeInfo.convertedDestAmount;
            }
            
            // TODO - check overflow
            actualSrcAmount = (actualDestAmount * PRECISION)/reserveInfo.rate;

            // do actual trade
            if( ! doSingleTrade( source,actualSrcAmount, dest, destAddress, reserveInfo.reserve, true ) ) {
                tradeInfo.tradeFailed = true;
                // trade failed in reserve
                ErrorReport( tx.origin, 0x86000002, tradeInfo.remainedSourceAmount );
                break;
            }

            // todo - check overflow
            tradeInfo.remainedSourceAmount -= actualSrcAmount;
            tradeInfo.convertedDestAmount += actualDestAmount;
        }
        
        if( tradeInfo.tradeFailed ) {
            if( throwOnFailure ) throw;
            if( msg.value > 0 ) {
                if( ! msg.sender.send(msg.value) ) throw;
            }
            
            return 0;
        }
        else {
            ErrorReport( tx.origin, 0, 0 );
            if( tradeInfo.remainedSourceAmount > 0 && source == ETH_TOKEN_ADDRESS ) {
                if( ! msg.sender.send(tradeInfo.remainedSourceAmount) ) throw;
            }
            
            
            
            ErrorReport( tx.origin, 0, 0 );
            Trade( msg.sender, source, dest, srcAmount-tradeInfo.remainedSourceAmount, tradeInfo.convertedDestAmount );
            return tradeInfo.convertedDestAmount;
        }
    }
    
    event AddReserve( KyberReserve reserve, bool add );
    function addReserve( KyberReserve reserve, bool add ) {
        if( msg.sender != admin ) {
            // only admin can add to reserve
            ErrorReport( msg.sender, 0x87000000, 0 );
            return;
        }
        
        if( add ) {
            reserves.push(reserve);
            AddReserve( reserve, true );
        }
        else {
            // will have truble if more than 50k reserves...
            for( uint i = 0 ; i < reserves.length ; i++ ) {
                if( reserves[i] == reserve ) {
                    if( reserves.length == 0 ) return;
                    reserves[i] = reserves[--reserves.length];
                    AddReserve( reserve, false );
                    break;
                }    
            }
        }
        
        ErrorReport( msg.sender, 0, 0 );
    }
    
    event ListPairsForReserve( address reserve, ERC20 source, ERC20 dest, bool add );
    function listPairForReserve(address reserve, ERC20 source, ERC20 dest, bool add ) {
        if( msg.sender != admin ) {
            // only admin can add to reserve
            ErrorReport( msg.sender, 0x88000000, 0 );
            return;
        }
        
        (perReserveListedPairs[reserve])[sha3(source,dest)] = add;
        ListPairsForReserve( reserve, source, dest, add );
        ErrorReport( tx.origin, 0, 0 );        
    }
    
    function upgrade( address newAddress ) {
        // TODO
        newAddress; // unused warning
        throw;
    }
    
    // should be called off chain with as much gas as needed
    function getReserves( ) constant returns(KyberReserve[]) {
        return reserves;
    }

    function getBalance( ERC20 token ) constant returns(uint){
        if( token == ETH_TOKEN_ADDRESS ) return this.balance;
        else return token.balanceOf(this);
    }
}