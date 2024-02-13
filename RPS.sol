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
    uint public timeout = 20 minutes;
    uint public numberreveal = 0 ;
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
//  input ใช้ไม่ไดถ้า reveal แล้วเปลี่ยน การ inputได้เลื่อยๆตาบที่ยังไม่เปิดเผย
    function input(uint choice) public  {
        uint idx = playernumber[msg.sender];
        require(numPlayer == 2);
        require(msg.sender == player[idx].addr);
        require(choice >= 0 && choice < 7);
        require(numberreveal == 0);
        //เปลี่ยน input ได้
        if (player[idx].input == false){
            player[idx].timestamps = block.timestamp;
            player[idx].input = true;
            numInput++;
        }
// hash ค่าที่เลือก
        bytes32 Hashdata = getHash(bytes32(choice));
        commit(Hashdata);
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

        restartgame();
    }
    function withdrawn() public {
        require(numPlayer == 1 || numPlayer == 2);
        require(msg.sender == player[0].addr || msg.sender == player[1].addr);
        uint idx = playernumber[msg.sender];
        if(numPlayer == 1){
            idx = 0;
        }
        //ไม่ยอม vote 1 คน
        else if(numPlayer == 2 && numInput < 2){
            require(player[idx].input == true);
        }
        else if (numPlayer == 2 && numInput == 2 && numberreveal < 2 ){
            require(commits[msg.sender].revealed == true);
        }
        require(msg.sender == player[idx].addr);
        require(block.timestamp - player[idx].timestamps > timeout);
        address payable  account = payable(player[idx].addr);
        account.transfer(reward);

        restartgame();
    }
    function restartgame() public {
        numPlayer = 0;
        reward = 0;
        numberreveal = 0 ;
        numInput = 0;

        address account0 = player[0].addr;
        address account1 = player[1].addr;

        delete playernumber[account0];
        delete playernumber[account1];
        delete player[0];
        delete player[1];
    }
}
