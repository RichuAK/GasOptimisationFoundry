// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    uint256 public immutable totalSupply;
    address public immutable contractOwner;
    address[5] public administrators;
    mapping(address => ImportantStruct) public whiteListStruct;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public balances;

    error GasContract__NotOwnerOrAdmin();
    error GasContract__NotCorrectlyWhitelisted();
    error GasContract__ZeroAddress();
    error GasContract__InsufficientBalance();
    error GasContract__NameTooLong();
    error GasContract__InvalidNumber();

    // enum PaymentType {
    //     Unknown,
    //     BasicPayment,
    //     Refund,
    //     Dividend,
    //     GroupPayment
    // }

    struct Payment {
        // PaymentType paymentType;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }

    modifier onlyAdminOrOwner() {
        if (contractOwner == msg.sender || checkForAdmin(msg.sender)) {
            _;
        } else {
            revert GasContract__NotOwnerOrAdmin();
        }
    }

    modifier checkIfWhiteListed(address sender) {
        uint256 usersTier = whitelist[msg.sender];
        if (usersTier == 0 || usersTier > 4) {
            revert GasContract__NotCorrectlyWhitelisted();
        }
        _;
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(address admin, uint256 ID, uint256 amount, string recipient);
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

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) public returns (bool) {
        if (balances[msg.sender] < _amount) {
            revert GasContract__InsufficientBalance();
        }
        if (bytes(_name).length > 8) {
            revert GasContract__NameTooLong();
        }
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        // payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
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

    function whiteTransfer(address _recipient, uint256 _amount) public checkIfWhiteListed(msg.sender) {
        whiteListStruct[msg.sender] = ImportantStruct(_amount, 0, 0, 0, true, msg.sender);
        if (balances[msg.sender] < _amount) revert GasContract__InsufficientBalance();
        if (_amount < 3) revert GasContract__InvalidNumber();
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
