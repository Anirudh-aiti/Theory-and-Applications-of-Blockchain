// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// 20CS30002,20CS30014,20CS30018,20CS10043
contract TicketBooking {
    address public seller;
    uint256 public numTicketsSold;
    uint256 public maxOccupancy;
    uint256 public price;

    struct Buyer {
        uint256 totalPrice;
        uint256 numTickets;
        string email;
    }

    mapping(address => Buyer) public buyersPaid;

    modifier soldOut() {
        require(numTicketsSold < maxOccupancy, "All tickets have been sold");
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == seller,
            "Only the contract owner can call this function"
        );
        _;
    }

    constructor(uint256 _maxOccupancy, uint256 _price) {
        seller = msg.sender;
        numTicketsSold = 0;
        maxOccupancy = _maxOccupancy;
        price = _price;
    }

    function buyTicket(string memory email, uint256 numTickets)
        public
        payable
        soldOut
    {
        require(msg.value >= price * numTickets, "Insufficient payment");
        require(
            numTicketsSold + numTickets <= maxOccupancy,
            "Insufficient number of tickets!"
        );

        // if already existing buyer
        if (buyersPaid[msg.sender].numTickets > 0) {
            buyersPaid[msg.sender].numTickets += numTickets;
            buyersPaid[msg.sender].totalPrice += msg.value;
        } else {
            buyersPaid[msg.sender] = Buyer(msg.value, numTickets, email);
        }

        numTicketsSold += numTickets;

        // if more amount was sent, refund extra amount
        if (msg.value > price * numTickets) {
            uint256 refundAmount = msg.value - (price * numTickets);
            payable(msg.sender).transfer(refundAmount);
            buyersPaid[msg.sender].totalPrice -= refundAmount;
        }
    }

    function withdrawFunds() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No money to withdraw");
        payable(seller).transfer(address(this).balance);
    }

    function refundTicket(address buyer) public onlyOwner {
        require(
            buyersPaid[buyer].numTickets > 0,
            "Buyer has not purchased any tickets"
        );

        payable(buyer).transfer(buyersPaid[buyer].totalPrice);
        numTicketsSold -= buyersPaid[buyer].numTickets;
        delete buyersPaid[buyer];
    }

    function getBuyerAmountPaid(address buyer) public view returns (uint256) {
        return buyersPaid[buyer].totalPrice;
    }

    function kill() public onlyOwner {
        selfdestruct(payable(seller));
    }
}

