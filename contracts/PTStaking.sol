// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PTStaking is Ownable {
    event STAKING(address indexed account, uint256 amount);
    event UNSTAKING(address indexed account, uint256 amount, uint256 rewards);
    event CLAIM(address indexed account, uint256 amount, uint256 rewards);

    struct StakingInfo {
        uint256 deposited;    
        uint256 timeOfLastUpdate;
        uint256 unclaimedHyco;
        uint256 unclaimedRewards;
        uint unclaimedTimes;
    }
    mapping(address => StakingInfo) internal _stakingInfos;

    uint256 public minStake = 100 * 10**18;
    uint256 public maxStake = 10000 * 10**18;
    uint256 public afterTime = 86400;
    uint256 public rewardPerTime = 3600;
    uint256 public endTimestamp = 1724220000;

    IERC20 private immutable HYCOToken;
    /**
     * @dev Set the ERC20 token address.
     */
    constructor(
        address erc20Address
    ) {
        HYCOToken = IERC20(erc20Address);      
    }

    function staking(uint256 _amount) public {
        require(_amount >= minStake, "Amount smaller than minimimum deposit");
        require(_amount + _stakingInfos[msg.sender].deposited <= maxStake, "Amount greater than maximum deposit");
        require(_amount%minStake == 0, "The amount is available in units of 100.");
        require(HYCOToken.balanceOf(msg.sender) >= _amount, "Not enough balance to complete transaction.");
        require(HYCOToken.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance to complete transaction.");
        require(endTimestamp > block.timestamp, "The staking period has ended.");
        
        bool success = HYCOToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(success, "Staking Failed");

        if (_stakingInfos[msg.sender].deposited == 0) {
            _stakingInfos[msg.sender].deposited = _amount;
            _stakingInfos[msg.sender].timeOfLastUpdate = block.timestamp;
        } else {
            uint256 rewards = calculateRewards(msg.sender);
            _stakingInfos[msg.sender].unclaimedRewards += rewards;
            _stakingInfos[msg.sender].deposited += _amount;
            _stakingInfos[msg.sender].timeOfLastUpdate = block.timestamp;
        }

        emit STAKING(msg.sender, _amount);
    }

    function unstaking(uint256 _amount) external {
        require(_stakingInfos[msg.sender].deposited > 0, "You have no staking");
        require(_amount%minStake == 0, "The amount is available in units of 100.");
        require(block.timestamp > _stakingInfos[msg.sender].timeOfLastUpdate + afterTime, "Unstaking requests can be made 24 hours after staking.");
        require(_stakingInfos[msg.sender].unclaimedHyco == 0, "You can unstake after claim.");
        require(
            _stakingInfos[msg.sender].deposited >= _amount,
            "Can't unstaking more than you have"
        );
        require(endTimestamp > block.timestamp, "The unstaking period has ended.");

        uint256 _rewards = calculateRewards(msg.sender);
        _stakingInfos[msg.sender].deposited -= _amount;
        _stakingInfos[msg.sender].timeOfLastUpdate = block.timestamp;
        _stakingInfos[msg.sender].unclaimedHyco += _amount;
        _stakingInfos[msg.sender].unclaimedRewards += _rewards;
        _stakingInfos[msg.sender].unclaimedTimes++;

        emit UNSTAKING(msg.sender, _amount, _rewards);
    }

    function claim() 
        external 
        returns (uint256 _rewards)
    {
        require(block.timestamp > _stakingInfos[msg.sender].timeOfLastUpdate + afterTime, "Claim requests can be made 24 hours after unstaking.");

        if (block.timestamp > endTimestamp + afterTime) {
            _stakingInfos[msg.sender].unclaimedHyco += _stakingInfos[msg.sender].deposited;
            _stakingInfos[msg.sender].unclaimedRewards += calculateRewards(msg.sender);
            _stakingInfos[msg.sender].deposited = 0;
        }
        require(_stakingInfos[msg.sender].unclaimedHyco > 0, "You have no reward");

        uint256 _amount = _stakingInfos[msg.sender].unclaimedHyco;
        _rewards = _stakingInfos[msg.sender].unclaimedRewards;

        bool success = HYCOToken.transfer(msg.sender, _amount);
        require(success, "Claim Failed");

        _stakingInfos[msg.sender].unclaimedHyco = 0;
        _stakingInfos[msg.sender].unclaimedRewards = 0;

        emit CLAIM(msg.sender, _amount, _rewards);

        return (_rewards);
    }

    function getStakingInfo(address _staker) 
        public view 
        returns (uint256 _deposited, 
            uint256 _startTimestamp, 
            uint256 _unClaimHyco, 
            uint256 _unClaimRewards, 
            uint256 _rewards, 
            uint _times
        )
    {
        _rewards = calculateRewards(_staker);

        return (_stakingInfos[_staker].deposited, 
            _stakingInfos[_staker].timeOfLastUpdate, 
            _stakingInfos[_staker].unclaimedHyco, 
            _stakingInfos[_staker].unclaimedRewards,
            _rewards, 
            _stakingInfos[_staker].unclaimedTimes
        );
    }

    function calculateRewards(address _staker)
        internal view
        returns (uint256 _rewards)
    {
        uint256 setTimestamp = block.timestamp;
        if (setTimestamp > endTimestamp) setTimestamp = endTimestamp;

        uint256 stakeHour = (setTimestamp - _stakingInfos[_staker].timeOfLastUpdate) / rewardPerTime;
        uint256 units = _stakingInfos[_staker].deposited / minStake;

        if (stakeHour > 2232) stakeHour = 2232;
        
        _rewards = stakeHour * units;

        return _rewards;
    }

    function setStakingInfo(address _staker, uint256 _amount, uint256 _setTime, uint256 _claimHyco, uint256 _rewards, uint256 _times) external onlyOwner {
        _stakingInfos[_staker] = StakingInfo(_amount, _setTime, _claimHyco, _rewards, _times);
    }

    function setMinStake(uint256 _value) external onlyOwner {
        minStake = _value;
    }

    function setMaxStake(uint256 _value) external onlyOwner {
        maxStake = _value;
    }

    function setAfterTime(uint256 _value) external onlyOwner {
        afterTime = _value;
    }

    function setRewardPerTime(uint256 _value) external onlyOwner {
        rewardPerTime = _value;
    }

    function setendTimestamp(uint256 _value) external onlyOwner {
        endTimestamp = _value;
    }

    function withdraw(address _walletAddress) external onlyOwner { 
        uint256 thisBalance = HYCOToken.balanceOf(address(this));
        if (thisBalance > 0) {
            HYCOToken.transfer(_walletAddress, thisBalance);
        }

        (bool os, ) = payable(_walletAddress).call{value: address(this).balance}("");
        require(os);
    }

}
