// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ERC20ClaimV1 is Ownable {

    event Claimed(address indexed account, uint256 amount);
    event Airdrop(address indexed account, uint256 amount);

    IERC20 private immutable _erc20;

    uint256 eventEndTimestamp = 1702173156;
    uint public eventTimes = 1;

    mapping(address => uint256) public claimList;
    mapping(address => uint) public eventClaimedList;
    mapping(uint => bytes32) public merkleRootMap;

    address public fromAddress = 0x43694Fd007a068909aC0951cFec4DfC6E3De42cf;
    address private _opAddress = 0x15CBB5AEdB860BD1e68252291049b26F54E22Ab4;

    
    /**
     * @dev Set the ERC20 token address.
     */
    constructor(
        address erc20Address
    ) {
        _erc20 = IERC20(erc20Address);
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in Claimlist!"
        );
        _;
    }

    function hycoAirdropFrom(address[] memory addresses, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            SafeERC20.safeTransferFrom(_erc20, fromAddress, addresses[i], amount);
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

    function hycoZKClaimFrom(address[] memory addresses, uint256[] memory amounts) 
        public 
    {
        require(msg.sender == _opAddress || msg.sender == owner(), "Caller is not the operator.");
        require(addresses.length == amounts.length, "Wrong data!");

        for (uint256 i = 0; i < addresses.length; i++) {
            SafeERC20.safeTransferFrom(_erc20, fromAddress, addresses[i], amounts[i]);

            emit Claimed(addresses[i], amounts[i]);
        }
    }

    function hycoClaimForWhite(bytes32[] calldata merkleProof, uint _claimAmount) public 
        isValidMerkleProof(merkleProof, merkleRootMap[_claimAmount])
    {
        require(eventEndTimestamp > block.timestamp, "The claim period has ended.");
        require(eventClaimedList[msg.sender] < eventTimes, "Aleady Claimed!");

        SafeERC20.safeTransferFrom(_erc20, fromAddress, msg.sender, _claimAmount*10*18);
        eventClaimedList[msg.sender] = eventTimes;

        emit Claimed(msg.sender, _claimAmount*10*18);
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

    function setEventClaimInfo(bytes32 _merkleRoot, uint _claimAmount) external onlyOwner {
        merkleRootMap[_claimAmount] = _merkleRoot;
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

    function getOpAddress() external view onlyOwner returns(address)
    {
        return _opAddress;
    }  

    function withdraw(address walletAddress) external onlyOwner 
    { 
        SafeERC20.safeTransfer(_erc20, walletAddress, IERC20(_erc20).balanceOf(address(this)));
    }

}
