// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./CommitReveal.sol";

contract RPS is CommitReveal {
    struct Player {
        uint choice; // 0 - Rock, 1 - Fire , 2 - Scissors, 3 - Sponge , 4 - Paper , 5 - Air , 6 - Water , 7 - undefind 
        address addr;
        uint timestamps;
        bool input;
    }
    uint public numPlayer = 0;
    uint public reward = 0;
    uint public timeout = 5 minutes;
    uint public numberreveal =0 ;
    uint public numInput = 0;

    mapping (uint => Player) public player;
    mapping (address => uint) public playernumber;

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.value == 1 ether,"input 1 ETH ");
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 7;
        player[numPlayer].timestamps = block.timestamp;
        player[numPlayer].input = false;
        playernumber[msg.sender] = numPlayer;
        numPlayer++;
    }
//  input ครบ 2 คนถึงจะยอมเปิด reveal
    function input(uint choice) public  {
        uint idx = playernumber[msg.sender];
        require(numPlayer == 2);
        require(msg.sender == player[idx].addr);
        require(choice >= 0 && choice < 7);
        player[idx].timestamps = block.timestamp;
        player[idx].input = true;
// hash ค่าที่เลือก
        bytes32 Hashdata = getHash(bytes32(choice));
        commit(Hashdata);
        numInput++;
    }
    
    function revealInput(uint choice)public {
        require(numInput == 2);
        reveal(bytes32(choice));
        uint idx = playernumber[msg.sender];
        player[idx].choice = choice; 
        numberreveal ++;
        if (numberreveal == 2){
            _checkWinnerAndPay();
        }
    }
    function _checkWinnerAndPay() private {
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if (p0Choice ==  p1Choice) {
            // to pay player[1]
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        else if ((p0Choice +3)%7 < p1Choice || p1Choice > p0Choice){
            account1.transfer(reward);
        }
        else {
            account0.transfer(reward);
        }
    }
}
