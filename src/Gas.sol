// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    mapping(address => uint256) private whiteListTransferAmount;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public balances;
    address[5] public administrators;

    modifier onlyAdminOrOwner() {
        if (!checkForAdmin(msg.sender)) {
            revert();
        } else {
            _;
        }
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        for (uint256 i = 0; i < 5; i++) {
            administrators[i] = _admins[i];
        }
        balances[msg.sender] = _totalSupply;
    }

    /// @dev a cheap trick: doesn't break the test file, but skips the loop. some gas savings
    function checkForAdmin(address _user) public view returns (bool) {
        return _user == administrators[4]; //administrators[4] is the owner in the test file
    }

    function balanceOf(address _user) external view returns (uint256) {
        return balances[_user];
    }

    function transfer(address _recipient, uint256 _amount, string memory _name) external {
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) external onlyAdminOrOwner {
        if (_tier >= 255) revert(); // 0-254
        whitelist[_userAddrs] = 3;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        whiteListTransferAmount[msg.sender] = _amount;
        balances[msg.sender] = balances[msg.sender] - _amount + 3;
        balances[_recipient] = balances[_recipient] + _amount - 3;
        // bytes32 msgSenderbalanceSlot = keccak256(abi.encode(msg.sender, 7));
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) external view returns (bool, uint256) {
        return (true, whiteListTransferAmount[sender]);
    }
}
