// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface INFTContract {
    function safeMint(address to) external;
}

contract DivasZkAirdrop is Ownable {
    using ECDSA for bytes32;
    
    bool isPaused = false;

    mapping(address => bool[3]) public claimedList;
    mapping(uint => uint256) public claimAmount;

    uint256 public endTimestamp = 1732917216;

    address private signerAddress;
    address public hubAddress;
    address public fromAddress = 0x643FF6fe36a18bF0d705fb89CEfC42deD01CF28d;

    IERC20 zkSyncErc20 = IERC20(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);

    event DivasZkAirdrop(string title, address to, uint256 amount);

    constructor(address _signerAddress) {
        signerAddress = _signerAddress;
        hubAddress = msg.sender;
        claimAmount[0] = 30000000000000000000;
        claimAmount[1] = 40000000000000000000;
        claimAmount[2] = 40000000000000000000;
    }

    modifier isSignatureValid(address receiver, string memory prefix, bytes memory signature, uint256 externalRandomValue) {
        bytes32 messageHash = keccak256(abi.encodePacked(prefix, receiver, externalRandomValue));
        address checkSigner = messageHash.toEthSignedMessageHash().recover(signature);

        require(checkSigner == signerAddress, "Invalid signature");
        _;
    }

    modifier claimCompliance() {
        require(endTimestamp > block.timestamp, "Claim has ended!");
        require(!isPaused, "Claim is paused!");
        _;
    }

    // 재진입 공격 방지: claimedList를 먼저 업데이트한 후 토큰 전송
    function zkAirdrop100Tran(bytes memory signature) public 
        claimCompliance() isSignatureValid(msg.sender, "zkAir100Tran", signature, claimAmount[0])
    {
        require(!claimedList[msg.sender][0], "Already claimed!");
        require(checkAllowanceAndBalance() > claimAmount[0], "Insufficient allowance or balance!");


        claimedList[msg.sender][0] = true;  // 먼저 상태 변경
        SafeERC20.safeTransferFrom(zkSyncErc20, fromAddress, msg.sender, claimAmount[0]);

        emit DivasZkAirdrop("zkAir100Tran", msg.sender, claimAmount[0]);
    }

    function zkAirdrop45KTP(bytes memory signature) public 
        claimCompliance() isSignatureValid(msg.sender, "zkAir45KTP", signature, claimAmount[1])
    {
        require(!claimedList[msg.sender][1], "Already claimed!");
        require(checkAllowanceAndBalance() > claimAmount[1], "Insufficient allowance or balance!");

        claimedList[msg.sender][1] = true;
        SafeERC20.safeTransferFrom(zkSyncErc20, fromAddress, msg.sender, claimAmount[1]);

    emit DivasZkAirdrop("zkAir45KTP", msg.sender, claimAmount[1]);
    }

    function zkAirdropZkPass(bytes memory signature) public 
        claimCompliance() isSignatureValid(msg.sender, "zkAirZkPass", signature, claimAmount[2])
    {
        require(!claimedList[msg.sender][2], "Already claimed!");
        require(checkAllowanceAndBalance() > claimAmount[2], "Insufficient allowance or balance!");

        claimedList[msg.sender][2] = true; 
        SafeERC20.safeTransferFrom(zkSyncErc20, fromAddress, msg.sender, claimAmount[2]);

    emit DivasZkAirdrop("zkAirZkPass", msg.sender, claimAmount[2]);
    }

    // 클레임 상태 확인 함수
    function getClaimedList(address _address) public view returns(bool[3] memory) {
        return (claimedList[_address]);
    }

    // 허용량 및 잔액 확인 함수
    function checkAllowanceAndBalance() public view returns (uint256) {
        uint256 allowance = zkSyncErc20.allowance(fromAddress, address(this));
        uint256 balance = zkSyncErc20.balanceOf(fromAddress);
        
        if (balance < claimAmount[0]) allowance = 0;

        return (allowance);
    }

    // 클레임 관련 정보 업데이트 함수들
    function setAmount(uint _type, uint256 _amount) external onlyOwner {
        claimAmount[_type] = _amount;
    }

    function setEndTimestamp(uint256 _endTimestamp) external onlyOwner {
        endTimestamp = _endTimestamp;
    } 

    function setPaused(bool _paused) external onlyOwner {
        isPaused = _paused;
    }
    
    function setFromAddress(address _fromAddress) external onlyOwner {
        fromAddress = _fromAddress;
    }

    function setHubAddress(address _address) external onlyOwner {
        hubAddress = _address;
    }

    function setErc20Contract(address _address) external onlyOwner {
        zkSyncErc20 = IERC20(_address);
    }

    // 컨트랙트의 잔액을 출금하는 함수
    function withdraw() external onlyOwner {
        (bool os, ) = payable(hubAddress).call{value: address(this).balance}("");
        require(os);
    }
}
