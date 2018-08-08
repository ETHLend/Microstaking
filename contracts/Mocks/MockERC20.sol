
import "../base/token/ERC20.sol";
import "../base/math/SafeMath.sol";


contract MockERC20 is ERC20 {

  using SafeMath for uint;
  
  string public name = "MockERC20";
  string public symbol = "MK20";
  uint256 public decimals = 18;
  uint public totalSupply;

  /**
  * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4) ;
    _;
  }

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;


function totalSupply() public view returns(uint){
    return totalSupply;
    
}
 function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32)  returns (bool success){
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    return true;
  }

 
  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
  
  function decimals() public view returns(uint){
      
      return decimals;
      
  }
  function sell(address _recipient, uint256 _value)  returns (bool success) {
      assert(_value > 0);

      balances[_recipient] = balances[_recipient].add(_value);
      totalSupply=totalSupply.add(_value);

      return true;
  }
}
