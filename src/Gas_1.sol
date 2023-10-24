// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    
    // Integrating Ownable logic
    uint256 public constant tradeFlag = 1;
    uint256 public constant basicFlag = 0;
    uint256 public constant dividendFlag = 1;
    mapping(address => uint256) public balances;
    mapping(address => bool) private _isAdmin;
    //address[] public administrators;
    uint256 private _totalSupply;
    address private _owner;
    uint256 private _paymentCounter = 0;
    //uint256 public constant tradePercent = 12;

    address private contractOwner;
    uint256 private tradeMode = 0;

    // Used packed structure
    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // Packed string
        address recipient;
        address admin;
        uint256 amount;
    }

    // Events are used for values that don't need to be stored long-term
    event PaymentHistoryAdded(uint256 lastUpdate, address updatedBy, uint256 blockNumber);
    event WhiteListTransfer(address indexed);

    struct ImportantStruct {
        uint256 amount;
        uint16 values;  // Packed values of valueA and valueB
        uint256 bigValue;
        bool paymentStatus;
        address sender;
    }

    mapping(address => ImportantStruct) private whiteListStruct;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    bool private isReady = false;

    enum PaymentType { Unknown, BasicPayment, Refund, Dividend, GroupPayment }
    event AddedToWhitelist(address userAddress, uint256 tier);



    constructor(address[] memory initialAdmins, uint256 totalSupply_) {
        _owner = msg.sender;
        _totalSupply = totalSupply_;
        balances[msg.sender] = totalSupply_;

        for (uint256 i = 0; i < initialAdmins.length; i++) {
            address admin = initialAdmins[i];
            require(!_isAdmin[admin], "Duplicate admin address");
            _isAdmin[admin] = true;
            administrators[i] = admin;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the contract owner");
        _;
    }

    // instead of the modifier since is used twice
    //modifier onlyAdminOrOwner() {
    //    require (_isAdmin[msg.sender], "Not an admin");
    //    _;
    //}

    //modifier checkIfWhiteListed() {
    //    address senderOfTx = msg.sender;
    //    uint256 usersTier = whitelist[senderOfTx];
    //    require(
    //        usersTier < 4 && usersTier >0,
    //        "Gas Contract CheckIfWhiteListed modifier : revert happened because the user's tier is incorrect, it cannot be over 4 as the only tier we have are: 1, 2, 3; therfore 4 is an invalid tier for the whitlist of this contract. make sure whitlist tiers were set correctly"
    //    );
    //    _;
    //}
    



    // ... [Some omitted for brevity]

    function transfer(address _recipient, uint256 _amount, string calldata _name) external returns (bool) {
        address sender = msg.sender;
        require(balances[sender] >= _amount, "Insufficient balance");
        balances[sender] -= _amount;
        balances[_recipient] += _amount;

        Payment memory payment = Payment({
            paymentType: PaymentType.BasicPayment,
            paymentID: ++_paymentCounter,
            adminUpdated: false,
            recipientName: _name,
            recipient: _recipient,
            admin: address(0),
            amount: _amount
        });
        
        payments[sender].push(payment);
        return true;
    }
    
    // perhaps not needed onlyAdminOrOwner
    //function updatePayment(address _user, uint256 _ID, uint256 _amount, PaymentType _type) 
    //external {
    //    for (uint256 i = 0; i < payments[_user].length; i++) {
    //        if (payments[_user][i].paymentID == _ID) {
    //            payments[_user][i].amount = _amount;
    //            payments[_user][i].paymentType = _type;
    //            payments[_user][i].adminUpdated = true;
    //            payments[_user][i].admin = _user;

                // Emitting instead of storing
    //            emit PaymentHistoryAdded(block.timestamp, _user, block.number);
    //        }
    //    }
    //}


    //checkIfWhiteListed() onlyAdminOrOwner
    function addToWhitelist(address _userAddrs, uint256 _tier) external onlyOwner {
       
        require(_tier >= 1 && _tier < 255, "Invalid tier value");
        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }
         emit AddedToWhitelist(_userAddrs, _tier);
    }

        function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public {
        address senderOfTx = msg.sender;
        whiteListStruct[senderOfTx] = ImportantStruct(_amount, 0, 0, true, msg.sender);
        
        require(
            balances[senderOfTx] >= _amount,
            "Gas Contract - whiteTransfers function - Sender has insufficient Balance"
        );
        require(
            _amount > 3,
            "Gas Contract - whiteTransfers function - amount to send have to be bigger than 3"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];
        
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) external view returns (bool, uint256) {        
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    
    // ... [Other functions]
}
