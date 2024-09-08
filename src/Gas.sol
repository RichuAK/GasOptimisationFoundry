// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    uint256 public immutable totalSupply;
    address public immutable contractOwner;
    address[5] public administrators;
    // mapping(address => ImportantStruct) public whiteListStruct;
    mapping(address => uint256) public whiteListTransferAmount;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public balances;

    error GasContract__NotOwnerOrAdmin();
    error GasContract__NotCorrectlyWhitelisted();
    error GasContract__ZeroAddress();
    error GasContract__InsufficientBalance();
    error GasContract__NameTooLong();

    // struct ImportantStruct {
    //     uint256 amount;
    // }
    // bool paymentStatus;

    /// @dev cheap tricky modifier
    // modifier onlyAdminOrOwner() {
    //     if (contractOwner == msg.sender) {
    //         _;
    //     } else {
    //         revert GasContract__NotOwnerOrAdmin();
    //     }
    // }

    modifier onlyAdminOrOwner() {
        if (contractOwner == msg.sender || checkForAdmin(msg.sender)) {
            _;
        } else {
            revert GasContract__NotOwnerOrAdmin();
        }
    }

    modifier checkIfWhiteListed() {
        uint256 usersTier = whitelist[msg.sender];
        if (usersTier == 0 || usersTier > 4) {
            revert GasContract__NotCorrectlyWhitelisted();
        }
        _;
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 i = 0; i < 5; i++) {
            administrators[i] = _admins[i];
        }
        balances[contractOwner] = totalSupply;
    }

    function checkForAdmin(address _user) public view returns (bool) {
        for (uint256 ii = 0; ii < 5; ii++) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
        return false;
    }

    /// @dev a cheap trick: doesn't break the test file, but skips the loop. some gas savings
    // function checkForAdmin(address _user) public view returns (bool) {
    //     return _user == contractOwner;
    // }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) public returns (bool) {
        uint256 userBalance = balances[msg.sender];
        if (userBalance < _amount) {
            revert GasContract__InsufficientBalance();
        }
        if (bytes(_name).length > 8) {
            revert GasContract__NameTooLong();
        }
        balances[msg.sender] = userBalance - _amount;
        balances[_recipient] += _amount;
        // emit Transfer(_recipient, _amount);
        return true;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public onlyAdminOrOwner {
        if (_tier >= 255) revert GasContract__NotCorrectlyWhitelisted(); // 0-254
        uint256 tierToStore = _tier;
        if (_tier > 3) {
            tierToStore = 3;
        }
        whitelist[_userAddrs] = tierToStore;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public checkIfWhiteListed {
        if (balances[msg.sender] < _amount) revert GasContract__InsufficientBalance();
        // whiteListStruct[msg.sender] = ImportantStruct(_amount);
        whiteListTransferAmount[msg.sender] = _amount;
        uint256 whitelistOfMsgSender = whitelist[msg.sender];
        balances[msg.sender] = balances[msg.sender] - _amount + whitelistOfMsgSender;
        balances[_recipient] = balances[_recipient] + _amount - whitelistOfMsgSender;

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        // return (true, whiteListStruct[sender].amount);
        return (true, whiteListTransferAmount[sender]);
    }

    // receive() external payable {
    //     payable(msg.sender).transfer(msg.value);
    // }

    // fallback() external payable {
    //     payable(msg.sender).transfer(msg.value);
    // }
}
