//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Payout {
    address[] public recipientList;
    mapping(address => bool) public isRecipient;
    mapping(address => uint256) public balances;
    address public owner;

    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event FundsDistributed(uint256 totalAmount);

    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    // Добавление нового адреса в список получателей
    function addRecipient(address recipient) public onlyOwner {
        require(!isRecipient[recipient], "Recipient already exists");
        recipientList.push(recipient);
        isRecipient[recipient] = true;
    }
    
    // Распределение средств с контракта между участниками
    function distributeFunds() public payable onlyOwner {
        uint256 totalAmount = msg.value;
        require(totalAmount > 0, "No funds to distribute");

        uint256 amountPerRecipient = totalAmount / recipientList.length;
        require(amountPerRecipient > 0, "Amount per recipient is too small");

        for (uint256 i = 0; i < recipientList.length; i++) {
            address recipient = recipientList[i];
            balances[recipient] += amountPerRecipient;
        }
        
        emit FundsDistributed(totalAmount);
    }
    
    // Запрос денег с контракта
    function requestFunds() public {
        address recipient = msg.sender;
        require(isRecipient[recipient], "You are not a recipient");
        uint256 amount = balances[recipient];
        require(amount > 0, "No funds available for withdrawal");
        
        balances[recipient] = 0;
        payable(recipient).transfer(amount);
        
        emit FundsWithdrawn(recipient, amount);
    }
    
    // Просмотр баланса контракта
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
