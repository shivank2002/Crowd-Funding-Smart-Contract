// SPDX-License-Identifier: GPL 3.0

pragma solidity >0.5.0 <0.9.0;

contract crowdFunding
{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public target;
    uint public DeadLine;
    uint public raisedAmount;
    uint public no_of_contributors;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint no_of_voters;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;
    uint public numRequest;

    constructor(uint _target, uint _deadline){
        target=_target;
        DeadLine=block.timestamp+_deadline;
        minimumContribution= 1 ether;
        manager=msg.sender;
    }

    function sendEth() public payable{
        require(block.timestamp < DeadLine, "DeadLine has passed");
        require(msg.value >= minimumContribution, "Minimum Contribution has not met");
        if(contributors[msg.sender]==0){
            no_of_contributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp> DeadLine && raisedAmount < target, "You are not eligible for refund");
        require(contributors[msg.sender]>0);
        address payable user= payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }
    modifier onlyManager(){
        require(msg.sender==manager, "Only Manager can call this function");
        _;
    }
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequest];
        numRequest++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.no_of_voters=0;
    }
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0, "You must be a contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.no_of_voters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage thisRequest= requests[_requestNo];
        require(thisRequest.completed=false, "this request has been completed");
        require(thisRequest.no_of_voters>no_of_contributors/2,"Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}
