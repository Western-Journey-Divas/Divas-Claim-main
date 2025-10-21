// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ERC20ClaimV2 is Ownable {
    using ECDSA for bytes32;

    event Claimed(address indexed account, uint256 amount);
    event Airdrop(address indexed account, uint256 amount);

    IERC20 private immutable _erc20;

    uint256 public eventEndTimestamp = 1708675200;
    uint public eventTimes = 1;

    string private _messagePrefix = "HYCO Claim";

    mapping(address => uint256) public claimList;
    mapping(address => uint) public eventClaimedList;

    address public fromAddress = 0xd4B11779a2dDAb1B49bcC873b87501f0C1319BFa;
    address public mktAddress = 0x643FF6fe36a18bF0d705fb89CEfC42deD01CF28d;
    address private _opAddress;

    /**
     * @dev Set the ERC20 token address.
     */
    constructor(
        address __erc20Address,
        address __opAddress
    ) {
        _erc20 = IERC20(__erc20Address);
        _opAddress = __opAddress;
    }

    modifier isSignatureValid(address receiver, bytes memory signature, uint requestAmount) {
        bytes32 messageHash = keccak256(abi.encodePacked(_messagePrefix, receiver, requestAmount));
        address checkSigner = messageHash.toEthSignedMessageHash().recover(signature);

        require(checkSigner == _opAddress, "invalid signature");
        _;
    }

    function hycoAirdropFrom(address[] memory addresses, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            SafeERC20.safeTransferFrom(_erc20, mktAddress, addresses[i], amount);
            emit Airdrop(addresses[i], amount);
        }
    }

    function hycoClaimFrom() public 
    {
        require(claimList[msg.sender] > 0, "Address does not exist in Claimlist!");

        SafeERC20.safeTransferFrom(_erc20, fromAddress, msg.sender, claimList[msg.sender]);
        claimList[msg.sender] = 0;

        emit Claimed(msg.sender, claimList[msg.sender]);
    }

    function hycoZKClaimFrom(address[] memory addresses, uint256[] memory amounts) public 
    {
        require(msg.sender == _opAddress || msg.sender == owner(), "Caller is not the operator.");
        require(addresses.length == amounts.length, "Wrong data!");

        for (uint256 i = 0; i < addresses.length; i++) {
            SafeERC20.safeTransferFrom(_erc20, fromAddress, addresses[i], amounts[i]);

            emit Claimed(addresses[i], amounts[i]);
        }
    }

    function hycoClaimForEvent(bytes memory signature, uint256 _claimAmount) public 
        isSignatureValid(msg.sender, signature, _claimAmount)
    {
        require(eventEndTimestamp > block.timestamp, "The claim period has ended.");
        require(eventClaimedList[msg.sender] < eventTimes, "Aleady Claimed!");

        SafeERC20.safeTransferFrom(_erc20, mktAddress, msg.sender, _claimAmount);
        eventClaimedList[msg.sender] = eventTimes;

        emit Claimed(msg.sender, _claimAmount);
    }

    function setClaimlist(address[] memory addresses, uint256[] memory amounts) 
        public 
    {
        require(msg.sender == _opAddress || msg.sender == owner(), "Caller is not the operator.");
        require(addresses.length == amounts.length, "Wrong data!");

        for (uint256 i = 0; i < addresses.length; i++) {
            if (claimList[addresses[i]] > 0) claimList[addresses[i]] += amounts[i];
            else claimList[addresses[i]] = amounts[i];
        }
    }

    function resetClaimlist(address[] memory addresses)
        public
    {
        require(msg.sender == _opAddress || msg.sender == owner(), "Caller is not the operator.");
        for (uint256 i = 0; i < addresses.length; i++) {
            claimList[addresses[i]] = 0;
        }
    }

    function setEventTimes(uint _times) external onlyOwner {
        eventTimes = _times;
    }

    function setEventEndTimestamp(uint256 _eventEndTimestamp) external onlyOwner {
        eventEndTimestamp = _eventEndTimestamp;
    } 

    function setOpAddress(address __opAddress) external onlyOwner
    {
        _opAddress = __opAddress;
    }

    function setFromAddress(address _fromAddress) external onlyOwner
    {
        fromAddress = _fromAddress;
    }

    function setMktAddress(address _fromAddress) external onlyOwner
    {
        mktAddress = _fromAddress;
    }

    function getOpAddress() external view onlyOwner returns(address)
    {
        return _opAddress;
    }  

    function withdraw(address walletAddress) external onlyOwner 
    { 
        SafeERC20.safeTransfer(_erc20, walletAddress, IERC20(_erc20).balanceOf(address(this)));

        (bool os, ) = payable(walletAddress).call{value: address(this).balance}("");
        require(os);
    }

}
