pragma solidity ^0.4.13;

contract Remittance{
    address public owner;
    uint public fee;
    uint public duration;

    mapping(bytes32=>Transfer) private transfers;

    struct Transfer{
        address creator;
        address recipient;
        uint amount;
        uint deadline;
    }

    function Remittance(uint transactionFee, uint transferDuration){
        owner = msg.sender;
        fee = transactionFee;
        duration = transferDuration;
    }

    modifier onlyMe(){
        require(msg.sender == owner);
        _;
    }

    function createTransfer(address transferRecipient, string pass1, string pass2) public payable returns(bool success){
        require(msg.value > fee);
        //check password hash isn't already in use
        require(transfers[keccak256(pass1,pass2)].amount == 0);

        Transfer memory newTransfer;
        newTransfer.creator = msg.sender;
        newTransfer.recipient = transferRecipient;
        newTransfer.amount = msg.value - fee;
        newTransfer.deadline = block.number + duration;
        transfers[keccak256(pass1,pass2)] = newTransfer;

        sendFee();

        return true;
    }

    function refundTransfer(string pass1, string pass2) public returns(bool success){
        Transfer memory toRefund = transfers[keccak256(pass1,pass2)];
        require(toRefund.amount > 0);
        require(msg.sender == toRefund.creator);
        require(block.number > toRefund.deadline);
        msg.sender.transfer(toRefund.amount);
        delete transfers[keccak256(pass1,pass2)];

        return true;
    }

    function sendFee() internal{
        owner.transfer(fee);
    }

    function withdrawFunds(string pass1, string pass2) public returns(bool success){
        Transfer memory toWithdraw = transfers[keccak256(pass1,pass2)];
        require(toWithdraw.amount > 0);
        require(block.number <= toWithdraw.deadline);
        toWithdraw.recipient.transfer(toWithdraw.amount);
        delete transfers[keccak256(pass1,pass2)];

        return true;
    }

    function kill() onlyMe() public{
        selfdestruct(owner);
    }
}
