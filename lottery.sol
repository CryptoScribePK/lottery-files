// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard {
    bool internal locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract VoodooLottery is ReentrancyGuard {
    uint256 private maxParticipantNumbers;
    uint256 private participantNumbers;
    uint256 private ticketPrice;
    address payable[] participants;
    address private owner;

    address private dev2 = 0x20c02a0BC56e3e5e580B7cCc39D8Da77f6ae7b4d;
    address private dev = 0x20c02a0BC56e3e5e580B7cCc39D8Da77f6ae7b4d;

    uint256 private maxParticipantNumbers1;
    uint256 private participantNumbers1;
    uint256 private ticketPrice1;
    address payable[] participants1;

    uint256 private maxParticipantNumbers2;
    uint256 private participantNumbers2;
    uint256 private ticketPrice2;
    address payable[] participants2;

    bool public initialization = false;
    bool public paused = false;
    address[] public winnerLottery;
    address[] public winnerLottery1;
    address[] public winnerLottery2;
    address public tokenAddress = 0x1c5f8e8E84AcC71650F7a627cfA5B24B80f44f00;
    IERC20 public VoodooInterface = IERC20(tokenAddress);

    // Track participant counts for efficiency
    mapping(address => uint256) private participantCount;
    mapping(address => uint256) private participantCount1;
    mapping(address => uint256) private participantCount2;

    constructor() {
        owner = msg.sender;
        maxParticipantNumbers = 10;
        ticketPrice = 10000 * 10**18; // 10,000 Voodoo (assuming 18 decimals)

        maxParticipantNumbers1 = 5;
        ticketPrice1 = 20000 * 10**18; // 20,000 Voodoo

        maxParticipantNumbers2 = 2;
        ticketPrice2 = 50000 * 10**18; // 50,000 Voodoo
    }

    // Events for transparency
    event LotteryStarted();
    event TicketPurchased(address indexed buyer, uint256 tier, uint256 amount);
    event WinnerSelected(address indexed winner, uint256 tier, uint256 amount);
    event TicketPriceUpdated(uint256 tier, uint256 newPrice);
    event Paused();
    event Unpaused();
    event TokensRecovered(address indexed token, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied!");
        _;
    }

    modifier notOwner() {
        require(msg.sender != owner, "Access denied");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function lotteryBalance() public view returns (uint256) {
        return VoodooInterface.balanceOf(address(this));
    }

    function setTicketPrice(uint256 _value) public onlyOwner {
        ticketPrice = _value;
        emit TicketPriceUpdated(0, _value);
    }

    function setTicketPrice1(uint256 _value) public onlyOwner {
        ticketPrice1 = _value;
        emit TicketPriceUpdated(1, _value);
    }

    function setTicketPrice2(uint256 _value) public onlyOwner {
        ticketPrice2 = _value;
        emit TicketPriceUpdated(2, _value);
    }

    function setMaximmNumbers(uint256 _maxNumbers) public onlyOwner {
        maxParticipantNumbers = _maxNumbers;
    }

    function setMaximmNumbers1(uint256 _maxNumbers) public onlyOwner {
        maxParticipantNumbers1 = _maxNumbers;
    }

    function setMaximmNumbers2(uint256 _maxNumbers) public onlyOwner {
        maxParticipantNumbers2 = _maxNumbers;
    }

    function viewTicketPrice() external view returns (uint256) {
        return ticketPrice;
    }

    function viewTicketPrice1() external view returns (uint256) {
        return ticketPrice1;
    }

    function viewTicketPrice2() external view returns (uint256) {
        return ticketPrice2;
    }

    function viewTicket() external view returns (uint256) {
        return maxParticipantNumbers;
    }

    function viewTicket1() external view returns (uint256) {
        return maxParticipantNumbers1;
    }

    function viewTicket2() external view returns (uint256) {
        return maxParticipantNumbers2;
    }

    function startLottery() public onlyOwner whenNotPaused {
        initialization = true;
        emit LotteryStarted();
    }

    function pause() public onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function recoverTokens(address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(owner, amount);
        emit TokensRecovered(token, amount);
    }

    function announceLottery() public onlyOwner whenNotPaused {
        require(participants.length > 0, "No participants");
        pickwinner();
    }

    function announceLottery1() public onlyOwner whenNotPaused {
        require(participants1.length > 0, "No participants");
        pickwinner1();
    }

    function announceLottery2() public onlyOwner whenNotPaused {
        require(participants2.length > 0, "No participants");
        pickwinner2();
    }

    function joinLottery(uint256 _amount) external notOwner whenNotPaused noReentrant {
        require(initialization, "Lottery not started");
        require(_amount == ticketPrice, "Incorrect ticket price");
        require(participantNumbers < maxParticipantNumbers, "Lottery is full");
        require(VoodooInterface.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");
        require(VoodooInterface.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        participants.push(payable(msg.sender));
        participantNumbers++;
        participantCount[msg.sender]++;
        emit TicketPurchased(msg.sender, 0, _amount);

        if (participantNumbers == maxParticipantNumbers) {
            pickwinner();
        }
    }

    function joinLottery1(uint256 _amount) external notOwner whenNotPaused noReentrant {
        require(initialization, "Lottery not started");
        require(_amount == ticketPrice1, "Incorrect ticket price");
        require(participantNumbers1 < maxParticipantNumbers1, "Lottery is full");
        require(VoodooInterface.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");
        require(VoodooInterface.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        participants1.push(payable(msg.sender));
        participantNumbers1++;
        participantCount1[msg.sender]++;
        emit TicketPurchased(msg.sender, 1, _amount);

        if (participantNumbers1 == maxParticipantNumbers1) {
            pickwinner1();
        }
    }

    function joinLottery2(uint256 _amount) external notOwner whenNotPaused noReentrant {
        require(initialization, "Lottery not started");
        require(_amount == ticketPrice2, "Incorrect ticket price");
        require(participantNumbers2 < maxParticipantNumbers2, "Lottery is full");
        require(VoodooInterface.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");
        require(VoodooInterface.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        participants2.push(payable(msg.sender));
        participantNumbers2++;
        participantCount2[msg.sender]++;
        emit TicketPurchased(msg.sender, 2, _amount);

        if (participantNumbers2 == maxParticipantNumbers2) {
            pickwinner2();
        }
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encode(blockhash(block.number - 1), block.timestamp, participants, block.number)));
    }

    function getLotteryLength() public view returns (uint256) {
        return participants.length;
    }

    function getLottery1Length() public view returns (uint256) {
        return participants1.length;
    }

    function getLottery2Length() public view returns (uint256) {
        return participants2.length;
    }

    function howMany(address ad) public view returns (uint256, uint256, uint256) {
        return (participantCount[ad], participantCount1[ad], participantCount2[ad]);
    }

    function pickwinner() internal {
        uint256 win = random() % participants.length;
        uint256 contractBalance = ticketPrice * participants.length;

        uint256 dev2Fee = (contractBalance * 10) / 100;
        uint256 devFee = (contractBalance * 10) / 100;
        uint256 winnerAmount = contractBalance - dev2Fee - devFee;

        require(VoodooInterface.transfer(dev2, dev2Fee), "Dev2 transfer failed");
        require(VoodooInterface.transfer(dev, devFee), "Dev transfer failed");
        require(VoodooInterface.transfer(participants[win], winnerAmount), "Winner transfer failed");

        winnerLottery.push(participants[win]);
        emit WinnerSelected(participants[win], 0, winnerAmount);

        // Clear participants
        for (uint256 i = 0; i < participants.length; i++) {
            participantCount[participants[i]] = 0;
        }
        delete participants;
        participantNumbers = 0;
    }

    function pickwinner1() internal {
        uint256 win = random() % participants1.length;
        uint256 contractBalance = ticketPrice1 * participants1.length;

        uint256 dev2Fee = (contractBalance * 10) / 100;
        uint256 devFee = (contractBalance * 10) / 100;
        uint256 winnerAmount = contractBalance - dev2Fee - devFee;

        require(VoodooInterface.transfer(dev2, dev2Fee), "Dev2 transfer failed");
        require(VoodooInterface.transfer(dev, devFee), "Dev transfer failed");
        require(VoodooInterface.transfer(participants1[win], winnerAmount), "Winner transfer failed");

        winnerLottery1.push(participants1[win]);
        emit WinnerSelected(participants1[win], 1, winnerAmount);

        // Clear participants
        for (uint256 i = 0; i < participants1.length; i++) {
            participantCount1[participants1[i]] = 0;
        }
        delete participants1;
        participantNumbers1 = 0;
    }

    function pickwinner2() internal {
        uint256 win = random() % participants2.length;
        uint256 contractBalance = ticketPrice2 * participants2.length;

        uint256 dev2Fee = (contractBalance * 10) / 100;
        uint256 devFee = (contractBalance * 10) / 100;
        uint256 winnerAmount = contractBalance - dev2Fee - devFee;

        require(VoodooInterface.transfer(dev2, dev2Fee), "Dev2 transfer failed");
        require(VoodooInterface.transfer(dev, devFee), "Dev transfer failed");
        require(VoodooInterface.transfer(participants2[win], winnerAmount), "Winner transfer failed");

        winnerLottery2.push(participants2[win]);
        emit WinnerSelected(participants2[win], 2, winnerAmount);

        // Clear participants
        for (uint256 i = 0; i < participants2.length; i++) {
            participantCount2[participants2[i]] = 0;
        }
        delete participants2;
        participantNumbers2 = 0;
    }

    function allWinner() public view returns (address[] memory) {
        uint256 arrayLength = winnerLottery.length;
        uint256 returnLength = arrayLength > 10 ? 10 : arrayLength;
        address[] memory result = new address[](returnLength);
        for (uint256 i = 0; i < returnLength; i++) {
            result[i] = winnerLottery[arrayLength - 1 - i];
        }
        return result;
    }

    function allWinner1() public view returns (address[] memory) {
        uint256 arrayLength = winnerLottery1.length;
        uint256 returnLength = arrayLength > 10 ? 10 : arrayLength;
        address[] memory result = new address[](returnLength);
        for (uint256 i = 0; i < returnLength; i++) {
            result[i] = winnerLottery1[arrayLength - 1 - i];
        }
        return result;
    }

    function allWinner2() public view returns (address[] memory) {
        uint256 arrayLength = winnerLottery2.length;
        uint256 returnLength = arrayLength > 10 ? 10 : arrayLength;
        address[] memory result = new address[](returnLength);
        for (uint256 i = 0; i < returnLength; i++) {
            result[i] = winnerLottery2[arrayLength - 1 - i];
        }
        return result;
    }
}
