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
        require(numPlayer < 2); ผู้เล่นจะเกิน 2 คนไม่ได้
        require(msg.value == 1 ether,"input 1 ETH "); ต้องใช้คนละ 1 ETH เท่านั้น
        reward += msg.value; เราจะเพิ่มค่ารางวัลเท่ากับที่ผู้เล่นใส่ลงมา
        player[numPlayer].addr = msg.sender; กำหนดให้ ค่าaddress ใน arrayplaye  = addres ของคนที่ส่ง api มา
        player[numPlayer].choice = 7;
        player[numPlayer].timestamps = block.timestamp; ไว้เก็บเวลาใน
        player[numPlayer].input = false;
        playernumber[msg.sender] = numPlayer;
        numPlayer++; ไป player ช่องต่อไป
        // addPlayer คือเราจะเพิ่มผู้เล่นเข้ามา 2 คน
    }
//  input ใช้ไม่ไดถ้า reveal แล้วเปลี่ยน การ inputได้เลื่อยๆตาบที่ยังไม่เปิดเผย
    function input(uint choice) public  {
    // จะให้ผู้เล่นทั้ง 2 ใส่ค่าโดยเราจะเก็บ เป็น ค่า Hash แทนเพื่อไม่ให้คนที่ลงมีหลังรู้ว่าคนแรกเลือกอะไร และจะไม่สามารถเปลี่ยน input ตัวเองได้ถ้าอีกคน reveal คำตอบไปแล้วแต่ถ้า numberreveal เป็น 0
    คือยังไม่มีใคร reveal คำตอบสามรถเปลี่ยน input ได้เลื่อยๆ และ ถ้าเป็นคนเดิมที่เปลี่ยน input ตัวเองเราจะไม่นับ numInput เพิ่มเนื่องจาก numInput ไว้เช็คว่าทั้ง 2 คนเลือกแล้วหรือยัง
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
    // function นี้ คือเราจะให้ทั้ง 2 คนเปิดเผยคำตอบตัวเองโดยต้องตรงกับ input ที่ใส่โดยต้องตรงกับ Hash ก่อนหน้าเด้วย ถ้าเปิดเผยคำตอบทั้ง 2 คนเสร็จแล้วก็จะไปคิดว่าใครชนะใน 
    _checkWinnerAndPay() 
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
    // เช็คว่าใครชนะรางวัลละจ่ายเงินไปให้ โดย เช็คเป็นช่วง คือ ถ้าอยู่ในช่วง (ตัวที่เลือก+3,ตัวที่เลือก) แปลว่าคนที่เลือกจะชนะเช่น 
    0 - Rock, 1 - Fire , 2 - Scissors, 3 - Sponge , 4 - Paper , 5 - Air , 6 - Water , 7 - undefind
    p0 เลือก 0-Rock ถ้า p1 อยู่ในช่วง (0,3] แปลว่า [1-Fire,2-Scissors,3-Spong] Rockจะชนะนอกเหนือนี้จะแพ้ และในดักกรณีที่เป็นตัวเดียวกันแต่แรกให้เป็นเสมอ  
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if (p0Choice ==  p1Choice) {
            // to pay player[1]
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        } เสมอ แบ่งเงินเท่ากัน
        else if ((p0Choice +3)%7 < p1Choice || p1Choice > p0Choice){
            account1.transfer(reward);
        } ถ้าไม่อยู่ในช่วย p1 ชนะ
        else {
            account0.transfer(reward);
        } ถ้าอยู่ในช่วง p0 ชนะ

        restartgame();
    }
    function withdrawn() public {
    // ให้ถอนเงินก่อนได้มี 3 กรณี
    ทุกกรณีต้องเกิน timeout ที่ตั้งไว้อันนี้ตั้งไว้ 20 นาที
    1) มีผู้เล่นมาเล่นแค่คนเดียว 
    2) มีผู้เล่นไม่ยอมใส่ input ยอมใส่inputแค่คนเดียว คนที่ใส่จะได้รางวัลทั้งหมด
    3) มีผู้เล่นไม่ยอม เปิดเผย input ตัวเองคนที่เปิดเผยจะได้เงินกันกรณีรู้ว่าแพ้แน่ๆเลยไม่ยอมเปิดเผย
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
    // เล่น เกมใหม่ ก็ reset ค่าเริ่มต้นให้ลงเดิมภันใหม่ได้
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
ภาพตัวอย่างการเล่น สัก 2 เกม
![image](https://github.com/ponzaa555/RPS/assets/100279911/355ea92a-5858-45f2-8acc-f7cc41161d22)




