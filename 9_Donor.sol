//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./8_Payout.sol";

contract Donors {

    mapping (address => uint256) public paymentsOf; //суммы
    mapping (address => uint256) public donationsBy; 
    address payable public owner;
    uint256 public balance;
    uint256 public withdrawn;
    uint256 public totalDonations = 0;
    uint256 public totalWithdrawal = 0;

    AggregatorV3Interface internal priceFeed; // Добавлен оракул


    event Donation(
        uint256 id,
        address indexed to,
        address indexed from,
        uint256 amount,
        uint256 timestamp
    );

    event Withdrawal(
        uint256 id,
        address indexed to,
        address indexed from,
        uint256 amount,
        uint256 timestamp
    );

    constructor() {
        owner = payable(msg.sender);
    }

    function donate() payable public {
        require(msg.value > 0, "Donation cannot be zero!");

        paymentsOf[msg.sender] += msg.value;
        donationsBy[msg.sender] += 1;
        balance += msg.value;
        totalDonations++;

        emit Donation(
            totalDonations, 
            address(this), 
            msg.sender, 
            msg.value, 
            block.timestamp
        );
    }

    function withdraw(uint256 amount, address payable payoutContractAddress) external returns (bool) {
        require(msg.sender == owner, "Unauthorized!");
        require(balance >= amount, "Insufficient balance");

        
        balance -= amount;
        withdrawn += amount;
        totalWithdrawal++;

        Payout payoutContract = Payout(payoutContractAddress);
        payoutContractAddress.transfer(amount);
        payoutContract.distributeFunds();

        emit Withdrawal(
            totalWithdrawal,
            msg.sender, 
            address(this),
            amount, 
            block.timestamp
        );
        return true;
    }

    function getUSDTPrice() public view returns (int) {
    (, int price, , , ) = priceFeed.latestRoundData();
    return price;
    } // Получает цену от оракула

    function getContractBalanceInUSDT() public view returns (int) {
        int usdtPrice = getUSDTPrice();
        int contractBalanceInUSDT = int(balance) * usdtPrice / 1e8; // Предполагается, что USDT имеет 8 десятичных знаков
        return contractBalanceInUSDT;
    } // Получает сумму контракта в USDT
}

contract ProxyContract {
    address public currentContractAddress;
    Donors public currentContract;

    constructor(address _mainContractAddress) {
        currentContractAddress = _mainContractAddress;
        currentContract = Donors(_mainContractAddress);
    }

    fallback() external payable {
        address impl = currentContractAddress;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    receive() external payable {}

    function updateContract(address newContractAddress) public {
        require(msg.sender == currentContract.owner(), "Only the owner can update the contract");
        currentContractAddress = newContractAddress;
        currentContract = Donors(newContractAddress);
    }
}